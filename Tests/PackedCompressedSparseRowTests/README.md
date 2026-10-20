# PackedCompressedSparseRow test suite

`PackedCompressedSparseRow<Vertex: Hashable>` is a directed graph with `AdjacencyList`'s API and
position rules over a packed memory array of rows: each out- and in-row is contiguous in slot
order with spare cells after it, so walks read the rows as compressed sparse rows and an insertion
moves O(log² n) cells amortized. This suite is the type's specification, on the public API plus
the lent rows (`_withOutIndexRows`).

The API is `AdjacencyList`'s, documented in `Tests/AdjacencyListTests/README.md`, and the catalog
conventions are `Tests/Catalogs/AdjacencyList/cases.md`'s. The suites here:

| File | Covers |
|---|---|
| `PackedCompressedSparseRowModelTests.swift` | Random operation sequences against a set model, on `Int` and `String` vertices, from a packed and an inserted start; every query, the dense indices, the lent rows' layout, attached maps through every rebalance, copies, bulk removals |
| `PackedCompressedSparseRowLayoutTests.swift` | The packed memory array: packed after a bulk build, spare cells spread by the first insertion, one row growing in place, doubling and halving, a removed slot's rows, offsets through rebalances |
| `PackedCompressedSparseRowConstructionTests.swift` | Bulk initializers, the builder and literal, copying any directed graph, the sorted construction protocol, equality and hashing, Codable, descriptions, generations, value semantics |
| `PackedCompressedSparseRowAlgorithmTests.swift` | Breadth-first layers, Dijkstra and strong components agree with `AdjacencyList` after a mixed workload; the lent rows are the queries' rows; attached maps through the index space |
| `PackedCompressedSparseRowPreconditionTests.swift` | Every trap in a child process, and the checked spellings that throw instead |
| `Performance/PackedCompressedSparseRowRatioTests.swift` | The lent rows walked and searched within 1.4× of packed arrays, bulk-built or built by insertion (release only) |

Mutants: `scripts/mutants/PackedCompressedSparseRowModule.py`. Fuzz target:
`Fuzz/Sources/FuzzPackedCompressedSparseRow`. Benchmarks:
`Benchmarks/Benchmarks/PackedCompressedSparseRowBenchmarks`.
