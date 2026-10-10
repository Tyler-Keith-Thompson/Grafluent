# Test catalog and design: `DisjointSet` (union–find)

This catalog covers Grafluent's planned `DisjointSet`, the only type in `DisjointSetModule`. The module is a 3-line stub today (`GF:Sources/DisjointSetModule/DisjointSetModule.swift:1-3`). `scripts/modules.py` describes it as "union–find with path compression and union by rank" with no dependencies (`GF:scripts/modules.py:26`). The README lists it as "Union–find with path compression and union by rank" with "Not a `Sequence`. `Sendable`, `Equatable` (same partition)" (`GF:README.md:294`). It will be used by `SpanningTrees` (Kruskal, Borůvka; `GF:scripts/modules.py:53`) and `Cycles` (`GF:scripts/modules.py:55`). `Connectivity` already lists it as a dependency but carries a private union–find for weak components: one `[Int]`, where a root holds minus its set's size and any other element holds its parent, with union by size and path halving (`GF:Sources/Connectivity/WeaklyConnectedComponents.swift:4-50, 96-108`).

It follows the format of `test-catalog-connectivity.md` and `test-catalog-csr.md`: a cross-library comparison, a decision table with evidence, a recommended API, then the cases. Case IDs `DS-nn` are stable, so test names can refer to them.

**Sources** (shallow clones, Oct 2026, not kept in the repository):

| Library | Commit | Licence | What was used |
|---|---|---|---|
| petgraph | `a4d94bd` | MIT OR Apache-2.0 | `src/unionfind.rs`, `tests/unionfind.rs`, `src/algo/mod.rs` (`connected_components`, `is_cyclic_undirected`), `src/algo/min_spanning_tree.rs` |
| Boost.Graph | `1ee1a99` | BSL-1.0 | `boost/pending/disjoint_sets.hpp`, `boost/pending/detail/disjoint_sets.hpp`, `test/disjoint_set_test.cpp`, the `disjoint_sets` doc page and its example with printed output, `kruskal_min_spanning_tree.hpp`, `incremental_components.hpp` |
| NetworkX | `6da4704` | BSD-3-Clause | `utils/union_find.py`, `utils/tests/test_unionfind.py`, `utils/misc.py` (`groups`), `algorithms/tree/mst.py` (Kruskal) |
| JGraphT | `63976aa` | EPL-2.0 OR LGPL-2.1+ | `alg/util/UnionFind.java`, `alg/util/UnionFindTest.java`, `alg/spanning/KruskalMinimumSpanningTree.java` |
| scipy | `ec1861f` | BSD-3-Clause | `scipy/_lib/_disjoint_set.py` (exported as `scipy.cluster.hierarchy.DisjointSet`), `scipy/cluster/hierarchy/tests/test_disjoint_set.py`, `benchmarks/benchmarks/cluster_hierarchy_disjoint_set.py`, `scipy/sparse/csgraph/_traversal.pyx` (`labels`). The checkout is sparse, so the first three were read with `git show HEAD:<path>`. |
| LEMON | `31d79d6` | Boost-style | `lemon/unionfind.h` (`UnionFind`, `UnionFindEnum`), `test/unionfind_test.cc`, `lemon/kruskal.h` |
| gonum | `0d48cee` | BSD-3-Clause | `graph/path/disjoint.go` and `disjoint_test.go` (private, used by Kruskal) |
| rustworkx | `25398ab` | Apache-2.0 | uses petgraph's `UnionFind` (`src/tree.rs:85-105`, `src/connectivity/mod.rs:511-515`); nothing of its own |
| igraph | `912f99d` | GPL-2.0+ (**behavior reference only; no code copied**) | `src/misc/spanning_trees.c:274-291`: Kruskal's private `get_comp`/`merge_comp`, with no balancing |
| swift-collections | `3b69ced` | Apache-2.0 | `HeapModule/Heap.swift` (a non-`Sequence` value type: `count`, `isEmpty`, `reserveCapacity`) |
| Swift stdlib | `5dc8186` | Apache-2.0 | `SetAlgebra.swift` (`union`/`formUnion`), `Equatable.swift` (substitutability), `Set.swift` |

None of the Swift clones (SwiftGraph, swift-algorithms, the stdlib) has a union–find. CLRS's `MAKE-SET`, `UNION` and `FIND-SET` are cited by name only.

**How the expectations were computed.** Values marked **(ref)** come from `ref.py` (next to this file). It has two models. `DS` is the recommended design: one array with negative sizes at roots, union by size with ties won by the smaller index, and path halving. `Naive` is an independent oracle: an owner array, member lists, and each set's representative maintained from sizes and representatives alone. `check.py` cross-checks them against **scipy's own `DisjointSet`**, run from source with its single import stubbed, and against **NetworkX's `UnionFind`**, run from the checkout. It covers 2420 seeded random operation sequences (n ∈ {0, 1, 2, 3, 10, 50, 1000}, with unions, `connected`, `subset_size` and `add` mixed in). It checks, after every operation, the union result, `n_subsets` and `subset_size`. At the end it checks the exact representative of every element, **the parent forest itself** (identical to scipy's, element by element), `subsets()` and its order, the labels, and the partition against NetworkX's `to_sets()`. All 1 064 620 checks pass. `cases.py` prints every value in §4 (`cases.out`). `rules.py` replays other libraries' linking rules. Its Boost rule reproduces the output printed in Boost's documentation (`find(0..5) = 1 1 1 4 4 5`), which validates the replay. `plant.py` plants 12 bugs and lists the cases that catch each one (§Q). Values marked **(scipy)** are scipy's own assertions, which hold verbatim because Grafluent adopts scipy's linking rule.

**Path prefixes** (relative to the root of those clones):

| Prefix | Expands to |
|---|---|
| `pg:` / `pg-T:` | `petgraph/crates/petgraph/src/unionfind.rs` / `petgraph/crates/petgraph/tests/unionfind.rs` |
| `pg-algo:` / `pg-mst:` | `petgraph/crates/petgraph/src/algo/mod.rs` / `src/algo/min_spanning_tree.rs` |
| `bgl:` / `bgl-d:` | `graph/include/boost/pending/disjoint_sets.hpp` / `graph/include/boost/pending/detail/disjoint_sets.hpp` |
| `bgl-T:` / `bgl-EX:` / `bgl-DOC:` | `graph/test/disjoint_set_test.cpp` / `graph/doc/modules/ROOT/examples/auxiliary/disjoint_sets.{cpp,txt}` / `graph/doc/modules/ROOT/pages/algorithms/utility/disjoint_sets.adoc` |
| `bgl-K:` / `bgl-IC:` | `graph/include/boost/graph/kruskal_min_spanning_tree.hpp` / `graph/include/boost/graph/incremental_components.hpp` |
| `nx:` / `nx-T:` / `nx-mst:` | `networkx/networkx/utils/union_find.py` / `networkx/networkx/utils/tests/test_unionfind.py` / `networkx/networkx/algorithms/tree/mst.py` |
| `jgt:` / `jgt-T:` / `jgt-K:` | `jgrapht/jgrapht-core/src/main/java/org/jgrapht/alg/util/UnionFind.java` / `jgrapht-core/src/test/java/org/jgrapht/alg/util/UnionFindTest.java` / `.../alg/spanning/KruskalMinimumSpanningTree.java` |
| `sp-ds:` / `sp-T:` / `sp-B:` | `scipy` at `ec1861f`: `scipy/_lib/_disjoint_set.py` / `scipy/cluster/hierarchy/tests/test_disjoint_set.py` / `benchmarks/benchmarks/cluster_hierarchy_disjoint_set.py` |
| `sp-cc:` | `scipy/scipy/sparse/csgraph/_traversal.pyx` (at `ec1861f`) |
| `lemon:` / `lemon-T:` / `lemon-K:` | `lemon/lemon/unionfind.h` / `lemon/test/unionfind_test.cc` / `lemon/lemon/kruskal.h` |
| `go:` / `go-T:` | `gonum/graph/path/disjoint.go` / `gonum/graph/path/disjoint_test.go` |
| `sc-heap:` | `swift-collections/Sources/HeapModule/Heap.swift` |
| `sw:` | `swift/stdlib/public/core/` |
| `GF:` | the Grafluent repository |

---

## 0. Cross-library comparison

| Question | Boost | petgraph | NetworkX | JGraphT | scipy | LEMON | gonum / igraph | Recommended for Grafluent |
|---|---|---|---|---|---|---|---|---|
| Elements | any, via `Rank`/`Parent` property maps (bgl:53-121); `disjoint_sets_with_storage` is dense `0..<n` through identity maps (bgl:121-199) | dense `0..<n` of an unsigned `IndexType` (pg:8-9, 53-62) | any hashable, two dicts (nx:31-44) | any `T`, `LinkedHashMap` + `HashMap` (jgt:46-55) | any hashable, four dicts (sp-ds:98-108) | items via an item→int map; storage dense (lemon:55-70, 91-96) | gonum: `map[int64]*dsNode` (go:7-8); igraph: dense vector (ig 274-291) | **dense `0..<count`** (D1) |
| Storage | parent + `unsigned char` rank (bgl:128) | `Vec<K>` parent + `Vec<u8>` rank, "separated out … to save cache" (pg:18-29) | `parents`, `weights` dicts | `parentMap`, `rankMap` | `_sizes`, `_parents`, `_nbrs` (circular member list), `_indices` (sp-ds:96-108) | **one `vector<int>`: a root holds minus its size, others their parent** (lemon:63-66) | pointer nodes with rank (go:52-56) | **one `[Int]`, LEMON's encoding** (= Connectivity's today) |
| Linking | union by rank (bgl-d:56-69) | union by rank (pg:205-216) | by weight = size, heaviest root first (nx:91-100) | union by rank (jgt:153-163) | **union by size** (sp-ds:37-38, 186) | **by size**, though the doc says "rank heuristic" (lemon:42-43, 139-145) | gonum: rank (go:19-34); igraph: none (ig:287-291) | **union by size** (D3) |
| Tie (equal rank/size) | **second** argument's root wins (`put(p, i, j)`, bgl-d:66) | **first** argument's root (pg:212-215) | arbitrary: `sorted` over a `set` (nx:94-97) | **first** (`parent1`, jgt:160-162), "No guarantees" (jgt:133-135) | **the root inserted first (smaller index)**, documented (sp-ds:166-168, 186) | **second** (`items[ka] = kb`, lemon:144) | gonum: first (go:30-33) | **smaller index, independent of argument order** (scipy) |
| Find | full compression by default (bgl:52, bgl-d:33-50); path halving optional (bgl:21-27, bgl-d:18-29) | `find(&self)` no compression (pg:100-121); `find_mut` path **splitting** (pg:129-153) | full compression, two passes with a path list (nx:55-66) | full compression, two passes (jgt:105-127) | **path halving** (sp-ds:36-37, 139-144) | full compression, two passes (lemon:74-85) | gonum: none (go:46-50); igraph: only the first element (ig:274-285) | **path halving**, iterative (D4) |
| Union's return | `void` (bgl:79-82) | **`bool`: "false if the sets were already the same"** (pg:177-186) | `None` | `void` (jgt:140) | **`True` "if x and y were in disjoint sets"** (sp-ds:175-178) | **`bool`** (lemon:126-132) | — | **`Bool`, `@discardableResult`** |
| Same-set query | `find_set(u) == find_set(v)` (bgl-IC:103) | `equiv` (pg:157-163) | `uf[u] != uf[v]` (nx-mst:235) | **`inSameSet`** (jgt:174-177) | `connected` (sp-ds:194-207) | compare `find` | — | **`inSameSet(_:_:)`** |
| Number of sets | `count_sets(first, last)`, an O(n) scan of roots (bgl:91-99) | — (`connected_components` dedups the labels, pg-algo:145-148) | — | **`numberOfSets()`**, O(1) counter (jgt:181-189) | **`n_subsets`**, O(1) (sp-ds:20, 191) | — | — | **`setCount`**, O(1) |
| Set size | — | — | `weights[root]` (internal) | — | **`subset_size(x)`** (sp-ds:232-249) | **`size(a)`** (lemon:149-155) | — | **`setSize(of:)`** |
| Enumerate sets | — (`normalize_sets`/`compress_sets` only, bgl:101-115) | `into_labeling`: the representative of each element (pg:220-231) | `to_sets()`: groups by root in insertion order (nx:72-89) | `toString` only (jgt:213-233) | **`subsets()`: sets in order of first element** (sp-ds:251-266); `subset(x)` via the circular list (sp-ds:209-230) | `UnionFindEnum` `ClassIt`/`ItemIt` (lemon:504-600) | — | **`sets()`** (D6) and **`labels()`** (D7) |
| Adding elements | `make_set(x)` (bgl:63-69); storage grows on `link` (`extend_sets`, bgl:188-199) | **`new_set()` returns the new index** (pg:82-94) | implicit on first lookup (nx:49-53) | `addElement`, throws if present (jgt:62-70) | `add`, idempotent (sp-ds:146-161) | `insert` returns the index (lemon:114-124) | `add` (go:10-16) | **`makeSet() -> Int`** (D8) |
| Capacity | — | `with_capacity`, `reserve`, `shrink_to_fit` (pg:238-420) | — | — | — | — | — | **`reserveCapacity(_:)`** |
| Out of range | UB | `find` panics; `try_*` return `None`/`Err` (pg:96-121, 165-197); `try_union(x, x)` is `Ok(false)` **even out of bounds** (pg:188-194) | auto-adds | `IllegalArgumentException` (jgt:107-110, 142-144) | `KeyError` (sp-ds:136-137, sp-T:82-95) | UB | `find` returns `nil` | **trap**, including `union(n, n)` (D10) |
| Value semantics | copy constructor shares property maps (bgl:62) | `Clone` (pg:17) | reference | reference | reference | reference | reference | **value type, copy-on-write** (D11) |
| Equality | — | — | — | — | — | — | — | **same partition** (D12) |

Consumers, for the API they need: Kruskal is "find both endpoints, compare, link" in Boost (bgl-K:86-92), JGraphT (jgt-K:67-71) and NetworkX (nx-mst:235-246). It is "join returns whether it merged" in LEMON (lemon-K:56, 85), petgraph and rustworkx (`if subgraphs.union(u, v)`, `rx: src/tree.rs:105`). Undirected cycle detection is `if !union(a, b) { return true }` (pg-algo:171-178). Connected components count distinct labels (pg-algo:137-148) or use dense labels (sp-cc:55-58, 88-92).

---

## 1. Decision table

| # | Question | Recommendation | Evidence | Disagreement / risk |
|---|---|---|---|---|
| D1 | Element model | **Dense `Int` elements `0..<count`, no generic parameter.** Every Grafluent consumer works in vertex-index space (`vertexIndexBound`, `vertexIndex(of:)`, `_DenseVertices`, `GF:Sources/Connectivity/DenseVertices.swift:3-30`). A union then costs two array walks with no hashing. That matches petgraph (pg:8-9), Boost's `disjoint_sets_with_storage` (bgl:121-140; its doc says the storage is "indexed by element ID", bgl-DOC), LEMON's storage and igraph. A hashable model costs 2–4 dictionary operations per step in NetworkX, JGraphT and scipy (nx:31-66, jgt:46-127, sp-ds:98-144), against the "match `Array`" target. | Kruskal, Borůvka, cycle detection and weak components all union endpoint indices. petgraph and rustworkx run them over `node_bound()` indices (pg-algo:137, pg-mst:94, `rx: src/tree.rs:85`). | Users with `String` elements map them to indices first, for example with `OrderedSet` from swift-collections. A generic type over a dense core can come later without changing this one. Its name is open question 1: NetworkX and JGraphT call their hashable structure `UnionFind`, and scipy calls its own `DisjointSet`. |
| D2 | Names | `DisjointSet`, `init()`, `init(count:)`, `count`, `isEmpty`, `setCount`, `makeSet()`, `reserveCapacity(_:)`, `find(_:)`, `union(_:_:)`, `inSameSet(_:_:)`, `setSize(of:)`, `sets()`, `labels()`. The sources are in §3. | **`union(_:_:)`**: petgraph, JGraphT, NetworkX and gonum all say `union`, and Boost says `union_set`. Its two arguments and `Bool` result keep it apart from `SetAlgebra.union(_:) -> Self` (sw:SetAlgebra.swift:118, 261). It is `mutating`, so on a `let` the compiler rejects it rather than letting a reader assume a new value comes back. **`setCount`**: Boost `count_sets`, JGraphT `numberOfSets` and scipy `n_subsets`, spelled the way `num_vertices`/`node_count` became `vertexCount` (`GF:Sources/GraphProtocols/DirectedGraph.swift:77`). | `union` reads like SetAlgebra's non-mutating noun. scipy's `merge` (sp-ds:163) follows Swift's mutating `Dictionary.merge` (sw:Dictionary.swift:1146) and avoids that. Alternative names: `merge(_:_:)` (open question 2), and `numberOfSets` (JGraphT verbatim) for `setCount`. `count` means elements, as in petgraph `len`, scipy `len` and JGraphT `size` (pg:73, sp-ds:117, jgt:196), and as in swift-collections' non-`Sequence` `Heap.count` (sc-heap:89). |
| D3 | Linking rule | **Union by size, with the size stored in the root's slot.** The root of the larger set stays the root. **When the sizes are equal, the root with the smaller index stays.** This is scipy's rule, word for word ("If the subsets are of equal size, the root element which was first inserted … is selected as the parent", sp-ds:166-168, 186). Insertion order is index order here. It is **documented** as the representative rule, so tests can pin every `find`. | Size gives `setSize(of:)` for free (scipy, LEMON) and needs no second array. petgraph's 1-byte rank array is a second allocation and a second cache line per union (pg:24-29). Size and rank give the same O(α(n)) bound with any of the compressions in D4 (Tarjan and van Leeuwen 1984). The tie rule is symmetric, so `union(a, b)` and `union(b, a)` leave identical state (DS-19, DS-25). That holds in no rank-based library: Boost's second-argument and petgraph/JGraphT's first-argument rules give different representatives (`rules.py`, §0). | It changes `scripts/modules.py:26` and `README.md:294` from "union by rank" to "union by size". The JGraphT sequence of DS-12 tells rank from size: rank gives representative 0, size gives 2. Documenting the rule commits to it. JGraphT refuses to (jgt:133-135), and NetworkX calls the name "arbitrarily-chosen" (nx:15). Open question 3. |
| D4 | Compression | **Path halving, iteratively, inside `find` and therefore inside `union`:** each element on the path is pointed at its grandparent. One pass, O(1) extra space, no recursion and no path buffer. **It never changes a root**, so representatives depend only on the successful unions, not on finds (DS-24). Implementation note: walk read-only first, and write only when the path has length ≥ 2. A `find` on an already flat path then never triggers copy-on-write (DS-B08). | scipy uses halving (sp-ds:36-37, 139-144), Boost offers it (bgl:21-27, bgl-d:18-29), and Connectivity's private `_find` already does it (`GF:Sources/Connectivity/WeaklyConnectedComponents.swift:96-108`). Full compression needs two passes (nx:55-66, jgt:105-127, lemon:74-85, bgl-d:33-50). petgraph's "recursive" `find_mut_recursive` is actually an iterative path *splitting* (pg:145-153). | Halving vs splitting vs full compression is invisible to every test (`plant.py`: removing compression is caught by nothing). DS-B06 decides it. The heights are bounded by ⌊log₂ n⌋ under D3 anyway (20 at n = 2²⁰, DS-41). |
| D5 | Does `find` mutate? | **`find`, `union`, `inSameSet` and `setSize(of:)` are `mutating`**, because they compress. `count`, `isEmpty`, `setCount`, `sets()`, `labels()`, `==`, `hash(into:)` and `description` are non-mutating and walk without writing. A `let` value can still answer every whole-partition question. | Every library that compresses does so in `find` (Boost `find_set`, JGraphT `find`, NetworkX `__getitem__`, scipy `__getitem__`, LEMON `find`). Swift cannot overload one name on `mutating`. The non-mutating walks cost O(log n) per element under D3 without the memo, O(1) amortized with it (D7). | petgraph offers both: `find(&self)` without compression and `find_mut` (pg:100, 129). A non-mutating `find` would need a second name, and none of the libraries has one beyond `_mut`. Kruskal, cycle detection and weak components only call `union`, `setCount` and `labels()` on a `var`, so the cost falls on nobody. Open question 4. |
| D6 | Enumerating the sets | **`sets() -> [[Int]]`**: the sets ordered by their smallest element, each listing its elements in ascending order. This is scipy's `subsets()` order (sets in order of first element, sp-ds:251-266; `sp-T:182-199` asserts it) and NetworkX's `to_sets()` order (dict-insertion grouping, nx:72-89, `utils/misc.py:265-268`). It is **canonical**: it depends only on the partition. | `DisjointSet` is not a `Sequence` (`GF:README.md:294`), as `Heap` is not (sc-heap:60-72). | scipy's members are Python sets, so their order is unspecified. Grafluent sorts them, which costs nothing because they are built by one ascending pass. No `subset(of:)`: scipy needs its circular `_nbrs` list for that (sp-ds:102, 209-230), which is one more `Int` per element. `sets()[labels()[x]]` gives the same answer. |
| D7 | Labels for consumers | **`labels() -> [Int]`**: for each element, the position of its set in `sets()`. So labels run over `0..<setCount` in order of each set's first element (DS-29). This is scipy's `connected_components` "length-N array of labels" (sp-cc:55-58, example `[0, 0, 0, 1, 1]` at sp-cc:88-92) and exactly what Connectivity computes today (`GF:Sources/Connectivity/WeaklyConnectedComponents.swift:64-80`). O(n) with one scratch array: memoize each element's root, so no element's path is walked twice. | `labels()` is a canonical form of the partition: two disjoint sets of the same count are equal iff their labels are equal. D12 and `hash(into:)` use that. | petgraph's `into_labeling` returns each element's **representative**, not a dense label (pg:220-231). A petgraph user may expect that, so the doc should say so. Labels numbered by representative instead of by first element are a planted bug that only DS-28 and DS-29 catch. |
| D8 | Growing | **`makeSet() -> Int`** (`@discardableResult`) appends a singleton and returns its element, `count` before the call. **`reserveCapacity(_:)`** reserves for that many elements in all, as `Array` (sw:Array.swift:1109) and `Heap` (sc-heap:137) do. **`init(count:)`** makes `count` singletons. No initializer from pairs and no `reset()`: `DisjointSet(count: n)` is the reset. | `makeSet` is Boost `make_set` (bgl:63-69) and CLRS `MAKE-SET`. The "returns the new index" contract is petgraph's `new_set` (pg:82-94) and LEMON's `insert` (lemon:114-124). petgraph's `uf_incremental` tests it (pg-T:182-213). | scipy's `add` is idempotent (sp-T:66-79) and JGraphT's `addElement` throws on a duplicate (jgt:62-70). With dense elements there is no duplicate to add, so neither applies. JGraphT's `reset()` (jgt:201-210) is not adopted. |
| D9 | `setSize(of:)` | O(α) amortized: `-storage[find(x)]`. | scipy `subset_size` (sp-ds:232-249) and LEMON `size` (lemon:149-155) read the root the same way. | — |
| D10 | Preconditions | Every element argument must be in `0..<count`, otherwise it **traps** with "Element \(x) is out of range 0..<\(count)", in the style of CSR's messages (`GF:Sources/CompressedSparseRowModule/CompressedSparseRow.swift:123-124`). `init(count:)` and `reserveCapacity(_:)` trap on a negative count. **`union(x, x)` checks `x` too**, unlike petgraph, which returns `Ok(false)` before the bounds check (pg:188-194). | Grafluent traps on invalid vertices (Traversal and Connectivity D20). Every library that checks rejects absent elements: scipy `KeyError` (sp-T:82-95), JGraphT `IllegalArgumentException` (jgt:107-110, 142-144), petgraph panics (pg:96-101, 177-186). | No `try` variants (petgraph's `try_find`/`try_union`): Grafluent does not throw for precondition failures. NetworkX's auto-add on lookup (nx:49-53) is not adopted. |
| D11 | Storage and copy-on-write | `@frozen public struct DisjointSet { var _storage: [Int]; var _setCount: Int }`, with `_storage[x] < 0` meaning x is a root and `-_storage[x]` its size. `Array` gives copy-on-write. `union` and `find` work through one `withUnsafeMutableBufferPointer` per call (one uniqueness check), after the range precondition. All `@inlinable`. **`Sendable`** follows. | LEMON (lemon:63-66) and Connectivity (`GF:Sources/Connectivity/WeaklyConnectedComponents.swift:4-6`) use the same encoding. The README's storage rule allows `Array` storage, which "already" has the standard library's CoW (`GF:README.md:298-300`). | A `ManagedBuffer` with `setCount` in its header would be one object instead of two fields. It saves nothing, since `Array` is already one allocation. `Int32` storage would halve memory below 2³¹ elements, but every Grafluent index is `Int` (DS-B06). |
| D12 | `Equatable` and `Hashable` | **Equal iff same `count` and the same partition**, so different representatives or tree shapes do not matter. It is implemented as `count`, `setCount` and `labels()` equal, plus an identical-storage fast path. **`Hashable`** hashes `count` and `labels()`, which is consistent with that. | The README promises "`Equatable` (same partition)" (`GF:README.md:294`). Consumers care about the partition: two Kruskal runs that merge the same components in a different order produce equal values (DS-31). A structural `==` that compares the parent arrays would make `union(1, 2); union(0, 1)` differ from `union(0, 1); union(1, 2)` (plant: caught by DS-31). Swift has precedent for a visible, non-salient aspect: two equal `Set`s can iterate in different orders. | `find` is visible and is **not** part of the value: in DS-31, equal values answer `find(0)` with 1 and 0. Swift requires such aspects to be "explicitly pointed out in documentation" (sw:Equatable.swift:112-117), so `find`'s doc must say so. The alternative is to compare the representatives too, which makes `==` depend on union order. Open question 5. `==` and hashing are O(n) and allocate. |
| D13 | Descriptions | `description`: the sets as `sets()` prints them, with at most 16 sets and 16 elements per set, then `…`: `[[0, 1, 3, 4, 7], [2], [5, 6]]`. `debugDescription`: `DisjointSet(count: 8, setCount: 3, sets: [[0, 1, 3, 4, 7], [2], [5, 6]])`. No representatives, so equal values print alike. | Grafluent's 16-item limit and the "equal values print alike" rule (`GF:Sources/GraphProtocols/GraphDescription.swift:1-9`, `GF:Sources/CompressedSparseRowModule/CompressedSparseRow.swift:699-717`). The module has no dependency on `GraphProtocols` (`GF:scripts/modules.py:26`), so it writes its own 10-line formatter. | JGraphT's `toString` shows each representative, `{rep:members}` (jgt:213-233). That would make equal values print differently. |
| D14 | `Codable` | **Not now.** No library serializes a union–find, and no Grafluent format needs one. If it comes later, encode `labels()`, which is canonical and validates in O(n). | — | Open question 6. |
| D15 | Recursion and depth | None: halving is a loop. Under D3 a tree's height is at most ⌊log₂ n⌋. Only root-to-root unions of equal sets reach it: the binomial tree of DS-41 has height 20 at n = 2²⁰. | (ref) `cases.py`: the element n − 1 is at depth 20 before any find. | Height cannot be observed through the public API (tests: public API only). It is a benchmark input (DS-B04). |
| D16 | Connectivity migration | Replace `_joinEndpoints`/`_find` (`GF:Sources/Connectivity/WeaklyConnectedComponents.swift:4-50, 96-108`) with `DisjointSet` **if DS-B07 shows ≤ 1.05× of the current private code**. `weaklyConnectedComponents()` becomes unions plus `labels()`, and `isWeaklyConnected` stops when `setCount == 1`. The labels are canonical, so the CN-tests do not change even though today's tie rule differs (first argument, line 23). | Connectivity already depends on `DisjointSetModule` (Connectivity catalog D9, open question 5). | If the struct's per-call uniqueness check and range check cost more than 5 % in DS-B07, keep the private code and record why. |

---

## 2. Recommended API sketch

```swift
// DisjointSetModule. Everything is @inlinable.

/// A partition of the elements `0..<count` into disjoint sets, with union by size and path
/// halving: O(α(n)) amortized per operation. (Boost `disjoint_sets`, petgraph `UnionFind`,
/// scipy `DisjointSet`.)
///
/// Each set's representative is one of its members. `union(a, b)` keeps the representative of
/// the larger set, or, for sets of the same size, the smaller of the two representatives. `find`
/// never changes a representative, so representatives depend only on which unions succeeded.
///
/// Two disjoint sets are equal when they partition the same elements the same way. The
/// representative `find` returns is not part of the value: equal disjoint sets can name the
/// same set differently.
@frozen public struct DisjointSet {
    /// No elements.                                     petgraph `new_empty`
    public init()
    /// `count` singletons. - Precondition: `count >= 0`. petgraph `new(n)`, Boost `(n)`
    public init(count: Int)

    /// The number of elements.                          petgraph `len`, scipy `len`, JGraphT `size`
    public var count: Int { get }
    public var isEmpty: Bool { get }
    /// The number of sets. O(1).                        Boost `count_sets`, JGraphT `numberOfSets`, scipy `n_subsets`
    public var setCount: Int { get }

    /// Adds the singleton `{count}` and returns it.     Boost `make_set`, petgraph `new_set`
    @discardableResult public mutating func makeSet() -> Int
    public mutating func reserveCapacity(_ minimumCapacity: Int)

    /// The representative of `element`'s set, halving the path to it.
    /// - Precondition: `element` is in `0..<count`.     Boost `find_set`, JGraphT/petgraph/LEMON `find`
    public mutating func find(_ element: Int) -> Int
    /// Merges the sets containing `a` and `b`. Returns whether they were different sets.
    /// - Precondition: both are in `0..<count`.         petgraph `union`, scipy `merge`, LEMON `join`
    @discardableResult public mutating func union(_ a: Int, _ b: Int) -> Bool
    /// Whether `a` and `b` are in the same set.        JGraphT `inSameSet`, petgraph `equiv`, scipy `connected`
    public mutating func inSameSet(_ a: Int, _ b: Int) -> Bool
    /// The number of elements in `element`'s set.      scipy `subset_size`, LEMON `size`
    public mutating func setSize(of element: Int) -> Int

    /// The sets, ordered by smallest element, each ascending. O(n).   scipy `subsets`, NetworkX `to_sets`
    public func sets() -> [[Int]]
    /// For each element, the position of its set in `sets()`. O(n).  scipy `connected_components` labels
    public func labels() -> [Int]
}
extension DisjointSet: Hashable {}            // same count and partition (labels)
extension DisjointSet: Sendable {}
extension DisjointSet: CustomStringConvertible, CustomDebugStringConvertible {}
```

Usage by the consumers:

```swift
var forest = DisjointSet(count: n)
for e in edgesByWeight where forest.union(e.source, e.target) {   // Kruskal
    tree.append(e)
    if forest.setCount == 1 { break }
}
let hasCycle = edges.contains { !forest.union($0.source, $0.target) }   // undirected cycle test
let labels = forest.labels()                                   // weak components, D16
```

---

## 3. Names and their sources

| Grafluent | From |
|---|---|
| `DisjointSet` | README (`GF:README.md:294`), scipy `DisjointSet`, Boost `disjoint_sets` |
| `init(count:)` | petgraph `UnionFind::new(n)`, Boost `disjoint_sets_with_storage(n)`; argument label as `Array(repeating:count:)` |
| `count`, `isEmpty` | petgraph `len`/`is_empty`, scipy `len`, JGraphT `size`; swift-collections `Heap` (sc-heap:81-92) |
| `setCount` | Boost `count_sets`, JGraphT `numberOfSets`, scipy `n_subsets` (spelled like `vertexCount`) |
| `makeSet()` | Boost `make_set`, CLRS `MAKE-SET`; return value from petgraph `new_set`, LEMON `insert` |
| `reserveCapacity(_:)` | Swift `Array`, `Heap`; petgraph `reserve` |
| `find(_:)` | petgraph, JGraphT, LEMON `find`; Boost `find_set`; CLRS `FIND-SET` |
| `union(_:_:)` | petgraph, JGraphT, NetworkX, gonum `union`; Boost `union_set`; CLRS `UNION` |
| `inSameSet(_:_:)` | JGraphT `inSameSet` |
| `setSize(of:)` | LEMON `size`, scipy `subset_size` |
| `sets()` | NetworkX `to_sets`, scipy `subsets` |
| `labels()` | scipy `connected_components` `labels` (sp-cc:55-58) |

---

## 4. Test catalog

Every case runs on the public API alone. "reps" lists `find(x)` for x in `0..<count`. "sizes" lists `setSize(of: x)`. Where a library's own assertion is weaker than the exact value, the catalog gives both. All values are (ref) unless marked.

### A. Construction

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-01 | The empty disjoint set | `DisjointSet()`: `count == 0`, `isEmpty`, `setCount == 0`, `sets() == []`, `labels() == []`, `description == "[]"` | pg:64-70 (`new_empty`) |
| DS-02 | `init(count: 0)` and one element | `DisjointSet(count: 0) == DisjointSet()`. `DisjointSet(count: 1)`: `find(0) == 0`, `setSize(of: 0) == 1`, `inSameSet(0, 0)`, `union(0, 0) == false`, `setCount == 1`, `sets() == [[0]]`, `labels() == [0]`, `!isEmpty` | — |
| DS-03 | The discrete partition | `DisjointSet(count: 8)`: reps `[0…7]`, `setCount == 8`, `sets() == [[0], [1], …, [7]]`, `labels() == [0, 1, …, 7]`, every size 1 | pg-T:10-17 (`find(i) == i`); sp-T:37-42 (`n_subsets == n`) |
| DS-04 | **Self-unions change nothing** | on `count: 8`: `union(i, i) == false` and `inSameSet(i, i)` for every i; afterwards `setCount == 8` and reps `[0…7]`; the value `==` a fresh `DisjointSet(count: 8)` | pg-T:16, 44, 75; sp-T:122-133 |
| DS-05 | `reserveCapacity` is invisible | `var d = DisjointSet(); d.reserveCapacity(100)`: `count == 0` and `d == DisjointSet()`; then 100 `makeSet()` calls give `d == DisjointSet(count: 100)`. `reserveCapacity(0)` on `count: 5` keeps it `==` | pg:271-283 |
| DS-06 | **`makeSet` from empty**: petgraph `uf_incremental`, translated | `makeSet()` returns 0, then 1, and `count == 2`. `union(0, 1)`. Then 2 and 3. `union(1, 3)`. Then 4. `union(1, 4)`. Then 5, 6 and 7, and `count == 8`. `union(4, 7)`, `union(5, 6)`. Now `inSameSet(0, 3)`, `inSameSet(1, 3)`, `!inSameSet(0, 2)`, `inSameSet(7, 0)`, `inSameSet(6, 5)`, `!inSameSet(6, 7)`, and `setCount == 3`. reps `[0, 0, 2, 0, 0, 5, 5, 0]`. The result is `==` DS-10's | pg-T:182-213 |
| DS-07 | `makeSet` on a non-empty set adds a singleton | `count: 3` after `union(0, 1)`: `makeSet() == 3`, `count == 4`, `setCount == 3`, `find(3) == 3`, `setSize(of: 3) == 1`, `!inSameSet(3, 0)`, `sets() == [[0, 1], [2], [3]]` | bgl:63-69; jgt-T:85-87 |

### B. Union

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-08 | **Union returns whether it merged, and is idempotent** | `count: 4`: `union(0, 1) == true`, `union(0, 1) == false`, `union(1, 0) == false`; `setCount` goes 4 → 3 and stays 3 | pg:177-186; sp-ds:175-178 (docstring: `merge('b', 'b')` is `False`); lemon:126-132 |
| DS-09 | Transitivity and symmetry of `inSameSet` | `count: 8`: `union(0, 1)` gives `inSameSet(0, 1)`. Then `union(1, 3)`, `union(1, 4)`, `union(4, 7)` give `inSameSet(0, 7)`, `inSameSet(1, 3)`, `!inSameSet(0, 2)`, `inSameSet(7, 0)`. `union(5, 6)` gives `inSameSet(6, 5)` and `!inSameSet(6, 7)` | pg-T:69-94 (`uf_test_with_equiv`) and 97-122 |
| DS-10 | **petgraph `uf_test`, exact** | `count: 8`, unions `(0,1), (1,3), (1,4), (4,7), (5,6)`, all `true`. reps `[0, 0, 2, 0, 0, 5, 5, 0]`, `setCount == 3`, `sets() == [[0, 1, 3, 4, 7], [2], [5, 6]]`, `labels() == [0, 0, 1, 0, 0, 2, 2, 0]`, sizes `[5, 5, 1, 5, 5, 2, 2, 5]`. petgraph asserts the three sets (pg-T:32-34); Boost's or LEMON's tie rule would give reps `[1, 1, 2, 1, 1, 6, 6, 1]` (`rules.py`) | pg-T:10-35 |
| DS-11 | petgraph `labeling`: two chains joined | `count: 48`. `union(i + 1, i)` for i in 0..<24, then `union(i, i + 1)` for i in 25..<47: `setCount == 2`, with representatives {0, 25}. Then `union(23, 25)` and `union(24, 23)`: `setCount == 1`, every rep 0, `labels()` all 0 | pg-T:167-180 |
| DS-12 | **JGraphT `testUnionFind`, translated** (`"aaa"…"eee"` → 0…4, its `TreeSet` order) | `count: 5`, `setCount == 5`. `union(0, 1)` gives 4, with `inSameSet(0, 1)` and `!inSameSet(1, 2)`. `union(2, 3)` gives 3. `union(2, 4)` gives 2. `union(2, 4)` again returns `false` and leaves 2. `union(0, 4)` gives 1, and **every rep is 2**: the size-3 set {2, 3, 4} absorbs the size-2 set {0, 1}. Union by rank sees equal ranks and gives 0 (`rules.py`). `makeSet() == 5`, so `setCount == 2` and `count == 6` | jgt-T:39-89 |
| DS-13 | Boost `disjoint_set_test`, translated | `count: 4`: all six pairs not in the same set. `union(0, 1)`, `union(2, 3)` give `find(0) != find(3)`. `a = find(0) = 0 == find(1)` and `b = find(2) = 2 == find(3)`. `union(a, b) == true` (Boost `link`), so `inSameSet(a, b)` and `setCount == 1`, with every rep 0 | bgl-T:28-55 |
| DS-14 | **Boost's documented example under Grafluent's rule** | `count: 6`, unions `(0,1), (1,2), (3,4)`: reps `[0, 0, 0, 3, 3, 5]`, `inSameSet(0, 2)`, `!inSameSet(0, 5)`, `sets() == [[0, 1, 2], [3, 4], [5]]`. Boost prints `1 1 1 4 4 5`, because its tie gives the second root (bgl-d:66). The difference is D3 | bgl-EX (`disjoint_sets.cpp`, `.txt`) |
| DS-15 | NetworkX `test_subtree_union` | `count: 6` (0 unused), unions `(1,2), (3,4), (4,5), (1,5)`: `sets() == [[0], [1, 2, 3, 4, 5]]`, reps `[0, 3, 3, 3, 3, 3]` | nx-T:15-24 |
| DS-16 | **NetworkX `test_unbalanced_merge_weights`: the larger set's representative wins** | `count: 10`, {1, 2, 3} by `(1,2), (2,3)` and {4…9} by `(4,5)…(8,9)`: `setSize(of: 1) == 3`, `setSize(of: 4) == 6`, `find(4) == 4`. Then `union(1, 4)`: `find(1) == 4` ("`uf[1] == largest_root`"), `setSize(of: 1) == 9`, reps `[0, 4, 4, 4, 4, 4, 4, 4, 4, 4]` | nx-T:37-47 |
| DS-17 | NetworkX `test_unionfind_weights` (variadic unions as chains) | `count: 10`: `(1,4), (4,7), (2,5), (5,8), (3,6), (6,9)` all `true`; then `(1,2), (2,3)` `true` and `(3,4)…(8,9)` all `false`; `setSize(of: 1) == 9`; reps `[0, 1, 1, 1, 1, 1, 1, 1, 1, 1]` | nx-T:27-34 |
| DS-18 | **LEMON `unionfind_test`, translated** (items 1…10, 0 unused; `insert(x, find(y))` becomes `union(x, y)`) | `count: 11`. `union(1, 2)`, `union(1, 4)` and `union(3, 5)` return `true`; `union(2, 4)` returns `false`. `union(8, 5)`. Sizes of 4, 5, 6 and 2 are `3, 3, 1, 3`. `union(10, 9)`, then `union(8, 10) == true`. Sizes of 4, 9 and 8 are `3, 5, 5`. reps `[0, 1, 1, 3, 1, 3, 6, 7, 3, 3, 3]`, `setCount == 5`, `sets() == [[0], [1, 2, 4], [3, 5, 8, 9, 10], [6], [7]]`. `erase`/`split`/`eraseClass` (lemon-T:75-99) have no Grafluent counterpart | lemon-T:36-73 |

### C. The representative rule (D3), exactly

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-19 | **Equal sizes: the smaller index wins, whatever the argument order** | `count: 4`: `union(3, 1)` and `union(1, 3)` both give reps `[0, 1, 2, 1]`. Under petgraph's and JGraphT's first-argument tie, `union(3, 1)` gives `[0, 3, 2, 3]` | sp-ds:166-168; sp-T:139-157 |
| DS-20 | **Larger set wins, whatever the indices** | `count: 8`: `union(5, 6)`, `union(6, 7)`, `union(0, 5)` → reps `[5, 1, 2, 3, 4, 5, 5, 5]` | sp-ds:166; nx-T:37-47 |
| DS-21 | **scipy `test_linear_union_sequence`**, n ∈ {10, 100} | Forwards, `union(i, i + 1)` for i = 0…n − 2: before each, `!inSameSet(i, i + 1)`; the union returns `true`; after it, `inSameSet(i, i + 1)` and `setCount == n − 1 − step`. Every rep is **0**. Backwards, i = n − 2…0: every rep is **n − 2** (8 and 98) (scipy). Either way, `union(0, n − 1) == false` at the end | sp-T:96-117 |
| DS-22 | **scipy `test_equal_size_ordering`, n = 10, exact pairs** | The pairs from `RandomState(0).shuffle` are `(2,8), (4,9), (1,6), (7,3), (0,5)`. Given as `(a, b)` and as `(b, a)`, every union returns `true` and reps are `[0, 1, 2, 3, 4, 0, 1, 3, 2, 4]`: each pair takes its smaller element (scipy asserts `elements[min(...)]`, sp-T:154) | sp-T:136-157 |
| DS-23 | **scipy `test_binary_tree`**, kmax ∈ {5, 10} (n = 32, 1024) | For k = 1, 2, 4, … < n, for each block start i (step 2k): pick any a in `i..<i+k` and b in `i+k..<i+2k` (scipy uses `RandomState(0)`; a `SeededRandomNumberGenerator` works, since the result does not depend on the picks). Then `!inSameSet(a, b)`, `union(a, b) == true`, `inSameSet(a, b)`. After each round, `find(x) == x − x % (2k)` for every x (scipy) | sp-T:160-179 |
| DS-24 | **`find` never changes a representative** | `count: 10` after DS-28's unions: call `find`, `inSameSet`, `setSize(of:)`, `sets()` and `labels()` on every element in random order, three times over. reps stay `[0, 7, 2, 0, 2, 0, 7, 7, 7, 7]` throughout. A failed `union` changes nothing either. ("as long as the set remains unchanged it will keep the same name", nx:15-17) | nx:15-17; D4 |
| DS-25 | **Argument order never matters** | Seeds 1…10, n = 200, 400 random pairs. Build `p` with `union(a, b)` and `q` with `union(b, a)`: the union results match pair by pair, and reps of p and q are identical (not merely `==`) | D3 |

### D. Counts and sizes

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-26 | `setCount` law | seeds 1…10, n ∈ {1, 10, 100}, 3n random unions with some `makeSet()` calls: `setCount == count − (number of unions that returned true)` after every step | jgt:164; sp-ds:191 |
| DS-27 | Size laws | same runs: `setSize(of: x) == sets()[labels()[x]].count` for every x; the sizes of the sets add up to `count`; after a `true` union of a and b, `setSize(of: a)` is the sum of the two sizes before it | sp-T:192 (`subset_size == len(subset)`) |

### E. `sets()` and `labels()`

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-28 | **scipy `test_subsets`, n = 10, exact trace** | pairs (`RandomState(0).randint(0, 10, (10, 2))`): `(5,0) T, (3,3) F, (7,9) T, (3,5) T, (2,4) T, (7,6) T, (8,8) F, (1,6) T, (7,7) F, (8,1) T`. `sets()` after each: `[[0,5],[1],[2],[3],[4],[6],[7],[8],[9]]`; unchanged; `[[0,5],[1],[2],[3],[4],[6],[7,9],[8]]`; `[[0,3,5],[1],[2],[4],[6],[7,9],[8]]`; `[[0,3,5],[1],[2,4],[6],[7,9],[8]]`; `[[0,3,5],[1],[2,4],[6,7,9],[8]]`; unchanged; `[[0,3,5],[1,6,7,9],[2,4],[8]]`; unchanged; `[[0,3,5],[1,6,7,8,9],[2,4]]`. Final reps `[0, 7, 2, 0, 2, 0, 7, 7, 7, 7]`, labels `[0, 1, 2, 0, 2, 0, 1, 1, 1, 1]`, sizes `[3, 5, 2, 3, 2, 3, 5, 5, 5, 5]`. scipy's own assertions (order of `subsets()` and `subset_size == len(subset)`) hold at every step | sp-T:182-199 |
| DS-29 | **Labels number sets by their first element, not by representative** | `count: 5` after `union(3, 0)`, `union(4, 1)`: `labels() == [0, 1, 2, 0, 1]`, `sets() == [[0, 3], [1, 4], [2]]`. `count: 4` after `union(2, 3)`, `union(0, 2)`: reps `[2, 1, 2, 2]` but `labels() == [0, 1, 0, 0]` and `sets() == [[0, 2, 3], [1]]` (numbering by representative would give `[1, 0, 1, 1]`) | sp-cc:88-92; `GF:Sources/Connectivity/WeaklyConnectedComponents.swift:64-78` |
| DS-30 | Consistency, and both work on a `let` | for every run of DS-26: `sets().count == setCount`; `sets().joined().sorted() == Array(0..<count)`; each set ascending and sets ordered by first element; `sets()[labels()[x]].contains(x)`; `labels().max() == setCount − 1` (or empty); and `let snapshot = d` compiles and calls `sets()`, `labels()`, `setCount`, `count`, `description` | D5, D6, D7 |

### F. Equality and hashing

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-31 | **Same partition, different representatives: equal** | `A = count: 3, union(1, 2), union(0, 1)` → reps `[1, 1, 1]`; `B = count: 3, union(0, 1), union(1, 2)` → reps `[0, 0, 0]`; `A == B`, `A.hashValue == B.hashValue`, `A.description == B.description == "[[0, 1, 2]]"`; and `A.find(0) != B.find(0)` (the documented non-value aspect, D12). Also: the 400 pairs of DS-25 applied in forward and reversed order give equal values | `GF:README.md:294`; sw:Equatable.swift:112-117 |
| DS-32 | Inequality | `DisjointSet(count: 3) != DisjointSet(count: 4)`; `count: 4` with `union(0, 1)` ≠ with `union(2, 3)` ≠ with nothing; `{0,1},{2,3}` ≠ `{0,2},{1,3}` (same `setCount`, same sizes); `count: 4` with `union(0, 1)` ≠ `count: 5` with `union(0, 1)` | — |
| DS-33 | Equality laws | reflexive after finds (`var c = d; _ = c.find(7); c == d`); `Set([A, B, DisjointSet(count: 3)]).count == 2`; equal after building the same partition via `makeSet()` vs `init(count:)` | D12 |

### G. Value semantics

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-34 | **A union on a copy leaves the original alone** | `var a = DisjointSet(count: 4); a.union(0, 1); var b = a; b.union(2, 3)`: `a.setCount == 3`, `!a.inSameSet(2, 3)`, `a.sets() == [[0, 1], [2], [3]]`; `b.sets() == [[0, 1], [2, 3]]`; and the other way round (mutate `a`, check `b`) | `GF:README.md:298-300` |
| DS-35 | **A compressing `find` on a copy changes neither** | the binomial tree of DS-41 at n = 2¹⁰: `var b = a; for x in 0..<1024 { _ = b.find(x) }`: `a == b`, reps of `a` still all 0; then `a.makeSet()`: `b.count == 1024` | D4, D11 |
| DS-36 | `makeSet` and `reserveCapacity` on a copy | `var b = a; b.makeSet(); b.reserveCapacity(10_000)`: `a.count` unchanged, `a == ` its earlier value | — |

### H. Preconditions (exit tests)

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-37 | **Out-of-range elements trap** | `await #expect(processExitsWith: .failure)` for each, on `DisjointSet(count: 8)`: `find(-1)`, `find(8)`, `union(0, 8)`, `union(8, 0)`, **`union(8, 8)`** (petgraph would return `false`, pg:192-194), `inSameSet(0, 8)`, `inSameSet(-1, 0)`, `setSize(of: 8)`; on `DisjointSet()`: `find(0)`, `union(0, 0)` | sp-T:82-95; pg-T:215-236; jgt:107-110, 142-144 |
| DS-38 | Negative counts trap | `DisjointSet(count: -1)`; `reserveCapacity(-1)` | `GF:Sources/CompressedSparseRowModule/CompressedSparseRow.swift:89-93` |

### I. Large inputs (10⁶, run in a `Task` like the Connectivity deep cases)

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-39 | **Chains and a star at n = 10⁶** | (a) `union(i, i + 1)` for i in 0..<n − 1: all `true`, `setCount == 1`, every rep 0, `setSize(of: 0) == 1_000_000`. (b) The same in reverse, i = n − 2…0: every rep **999 998** (scipy's backwards law at scale). (c) `union(i + 1, i)` forwards: every rep 0. (d) `union(i, 0)` for i in 1..<n: every rep 0. In each, `labels()` is all zeros and `sets().count == 1` | sp-T:96-117 |
| DS-40 | **Randomized differential against a naive reference** | A test-local naive model: `owner: [Int]`, `members: [[Int]]`, and each set's representative updated by D3 from the two sizes and representatives. Seeds 1…30, n ∈ {1, 2, 10, 100, 1000}, 4n operations: 5 % `makeSet()`, otherwise random `union`, `inSameSet` or `setSize(of:)`. After every step it checks the result, `setCount`, `count` and the size. At the end it checks reps, `sets()`, `labels()`, and `==` with a value rebuilt from the naive partition in a different union order | `check.py` (same oracle, cross-checked against scipy and NetworkX) |
| DS-41 | **Maximum height: the binomial tree**, n = 2²⁰ | for k = 1, 2, 4, …, 2¹⁹ and i stepping by 2k: `union(i, i + k)`. Both arguments are roots of equal-size sets, so every call returns `true` and no compression happens. Element n − 1 sits at depth 20 (internal). Then `setCount == 1`, `find(n − 1) == 0`, and every rep is 0 | D15; (ref) |
| DS-42 | petgraph's `uf_rand` law | `count: 2¹⁴`, 100 random pairs, and `count: 256`, 2048 pairs (petgraph's `uf_u8` sizes): before each union compute `let separate = find(a) != find(b)`; then `union(a, b) == separate` | pg-T:124-164 |
| DS-43 | 10⁶ random unions, order independence | n = 10⁶, 10⁶ seeded random pairs: `setCount == n − trues`; the same pairs in reverse order (and with swapped arguments) give an `==` value with equal `labels()` | D12 |

### J. Descriptions and conformances

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-44 | `description` / `debugDescription` | DS-10's value: `"[[0, 1, 3, 4, 7], [2], [5, 6]]"` and `"DisjointSet(count: 8, setCount: 3, sets: [[0, 1, 3, 4, 7], [2], [5, 6]])"`; `DisjointSet()` → `"[]"` and `"DisjointSet(count: 0, setCount: 0, sets: [])"`; `DisjointSet(count: 20)` lists 16 singletons then `…`; one set of 20 lists 16 elements then `…` | D13 |
| DS-45 | `Sendable` | a `DisjointSet` crosses into a `Task` and back (compile-time) | D11 |
| DS-46 | Consumer patterns | petgraph's `connected_components` example: `count: 8`, union a→b→c→d→a and e→f→g→h→e (`(0,1),(1,2),(2,3),(3,0),(4,5),(5,6),(6,7),(7,4)`) returns `T, T, T, F, T, T, T, F`; `setCount == 2`; `labels() == [0, 0, 0, 0, 1, 1, 1, 1]`; then `union(1, 4) == true` and `setCount == 1`. The triangle `(0,1),(1,2),(2,0)` returns `T, T, F`, so the third edge closes the cycle | pg-algo:100-131, 171-178 |

---

### Q. Planted bugs the suite must catch

Planted in the reference (`plant.py`), which reruns the listed cases against each variant.

| Bug | Caught by |
|---|---|
| Ties won by the first argument's root (petgraph, JGraphT, today's Connectivity) | DS-19, DS-22, DS-28, DS-40 |
| Ties won by the second argument's root (Boost, LEMON) | DS-10, DS-12, DS-14, DS-16, DS-18 – DS-23, DS-28, DS-31, DS-40 |
| Union by rank instead of size | DS-12, DS-16, DS-40 |
| No balancing (always link b's root under a's) | DS-12, DS-16, DS-18 – DS-22, DS-28, DS-31, DS-40 |
| Size not added to the surviving root | DS-10, DS-12, DS-16, DS-18, DS-20, DS-21, DS-28, DS-31, DS-40 |
| `union(x, x)` returns `true` | DS-04, DS-28, DS-40 |
| `setCount` decremented on a failed union | DS-04, DS-12, DS-28, DS-40 |
| `makeSet` does not count the new set | DS-06, DS-12, DS-40 |
| Labels numbered by ascending representative | DS-28, DS-29 |
| `sets()` members in tree order (root first) | DS-28, DS-40 |
| `==` compares the parent arrays | DS-31 |
| `union(n, n)` short-circuits before the bounds check (petgraph's `try_union`; by construction) | DS-37 |
| Recursive find (by construction) | none at the API level: heights are ≤ 20 under D3 (DS-41). Benchmarks only |
| No path compression at all | **not observable** (by design: D4); DS-B06 |

### R. Benchmarks (not tests)

All use n = 10⁶ unless stated. The baseline is a **hand-written union–find**: one `[Int]` with negative sizes at the roots, union by size and path halving, all inside a single `withUnsafeMutableBufferPointer`. That is today's `_joinEndpoints` (`GF:Sources/Connectivity/WeaklyConnectedComponents.swift:4-50`), copied into the benchmark.

| ID | Measures | Target |
|---|---|---|
| DS-B01 | `union` over 10⁶ and 4 × 10⁶ seeded random pairs, from fresh `init(count:)` (scipy's `time_merge`, sp-B) | ≤ 1.1× the hand-written loop |
| DS-B02 | `union` over already-merged pairs (`time_merge_already_merged`, sp-B), the Kruskal tail | ≤ 1.1× |
| DS-B03 | Kruskal-shaped: unions over the edges of a seeded G(n, 4n) in a fixed shuffled order, stopping at `setCount == 1` | ≤ 1.1× |
| DS-B04 | `find` on every element after B01 (`time_find`), and again after full compression (`time_find_already_found`); also on DS-41's binomial tree | ≤ 1.1× |
| DS-B05 | `labels()` and `sets()` after B01, vs the hand-written numbering pass (`GF:Sources/Connectivity/WeaklyConnectedComponents.swift:64-78`) | ≤ 1.2× |
| DS-B06 | Heuristic matrix, internal variants: path halving / splitting / full compression / none × size / rank, on B01, B03, B04; `Int` vs `Int32` storage; the cost of the smaller-index tie compare | decides D4; reports D11 |
| DS-B07 | `weaklyConnectedComponents()` with `DisjointSet` vs with today's private code (Connectivity CN-B04 inputs) | ≤ 1.05× decides D16 |
| DS-B08 | Copy-on-write: `var b = a; b.find(x)` for 10⁶ x on a fully compressed `a`. With the read-first `find` of D4 it must not copy the storage (measure allocations) | 0 extra allocations |
| DS-B09 | `==` and `hash(into:)` on equal 10⁶-element values built in different orders, and the identical-storage fast path | report |
| DS-B10 | `init(count:)` vs `[Int](repeating: -1, count:)`; `makeSet()` ×10⁶ with and without `reserveCapacity` | ≤ 1.05× |

---

## Deferred

- **A generic `Hashable` disjoint set** over the dense core, mapping elements with `OrderedSet`, as in NetworkX, JGraphT and scipy (open question 1).
- **`subset(of:)` in O(set size)**: scipy's circular member list (sp-ds:102, 189, 209-230) or LEMON `UnionFindEnum` (lemon:159-600). It costs one more `Int` per element. `sets()` covers the uses known today.
- **Deleting and splitting**: LEMON's `erase`, `split` and `eraseClass` (lemon:420-500). Incremental connectivity in the style of Boost `incremental_components` (bgl-IC) belongs in Connectivity.
- **`link(_:_:)`** on two known representatives, Boost's `link` (bgl:72-76). Kruskal in Boost uses it after `find_set` (bgl-K:86-92). `union` does both finds itself, and a precondition "both are roots" is easy to break.
- **`Codable`** (D14).
- **Normalizing representatives** to the smallest element: Boost `normalize_sets`, postcondition `v >= parent[v]` (bgl:101-106, bgl-d:71-89). It would make `find` part of the value (D12), but needs an O(n) pass or a second array.

---

## Open questions for the maintainer

1. **Element model (D1).** Dense `0..<count` only, or a generic `Hashable` type as well? If generic, which non-invented name: `UnionFind<Element>` (NetworkX and JGraphT, though petgraph's `UnionFind` is dense) or a generic `DisjointSet<Element>` (scipy), which would break the dense one later?
2. **`union` vs `merge` (D2).** `union(_:_:)` follows five libraries and CLRS. scipy's `merge(_:_:)` matches Swift's mutating `Dictionary.merge` and does not echo `SetAlgebra.union`.
3. **Documenting the representative (D3).** Pin scipy's rule (larger set, then smaller index), so that tests and callers can rely on `find`? Or say "unspecified", as JGraphT and NetworkX do? This also changes "union by rank" to "union by size" in `scripts/modules.py:26` and `README.md:294`.
4. **Mutating queries (D5).** `find`, `inSameSet` and `setSize(of:)` are `mutating` so they can compress. A non-mutating `find` would need a second name, and the libraries offer only petgraph's `find`/`find_mut` pair.
5. **Equality (D12).** Partition equality (the README's promise), with `find` documented as a non-value aspect, or equality that also compares representatives?
6. **`Codable` (D14).** Skip, or encode `labels()`?
7. **Connectivity (D16).** Migrate weak components onto `DisjointSet` once DS-B07 shows ≤ 1.05×?
