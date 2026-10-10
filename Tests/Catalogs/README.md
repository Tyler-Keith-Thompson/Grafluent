# Test catalogs

Each module's test suite was designed from a catalog: a table of cases harvested from other graph
libraries (NetworkX, igraph, rustworkx, Boost.Graph, LEMON, JGraphT, petgraph, scipy) and the
literature. Each case has an ID (`CO-017`, `MA-164`, …), a graph, a query and an expected value. The test files and
READMEs in `Tests/<Module>Tests/` cite those IDs. This folder keeps the catalogs, so every expected
value can be traced and recomputed.

One folder per test suite, named after it without `Tests` (`ColoringModule/` for
`Tests/ColoringModuleTests/`). A folder holds some of:

| File | What it is |
|---|---|
| `cases.md` | The case table: ID, input, query, expected value, source. The test names refer to its IDs. |
| `api.md` | The design notes the tests were written against: the proposed API, the decisions taken on open questions, the complexity table. |
| `ref.py` | The reference model: an independent Python implementation of the API (in index space, usually with brute-force oracles from the definitions), cross-checked against NetworkX and the other libraries. Running it re-evaluates every row and checks that it agrees with `cases.md`. |
| `swiftgen.py`, `gen.py`, `gen_tests.py` | The generator: re-evaluates each row with `ref.py`, asserts the value equals the catalog cell, and writes the catalog-row Swift test files. It regenerates the committed tests byte for byte. |
| `extra_*.swift`, `*.part`, `rep_*.swift`, `parts/` | Generator inputs: hand-written Swift spliced into a generated file. Not compiled. |
| `cases.py` / `cases.out`, `stress_vals*.py`, `extra*.py`, `conf_vals.py` | Scripts that print literals the tests quote (stress-test values, conformance values), with the output kept where the tests compare against it. |

The folder is not a SwiftPM or Bazel target: `Package.swift` declares no target here, and
`.bazelignore` lists it, so the `.swift` files in it are never compiled.

## Running

Run from the repository root. Scripts find their files relative to their own location. Python
dependencies come through `uv` with the versions `scripts/differential.py` pins, so nothing is
installed globally:

```sh
UV="uv run --quiet --no-project --with networkx==3.7"     # add the extra pins a module needs:
#   --with scipy==1.18.1   --with rustworkx==0.18.1   --with igraph==1.0.0
```

A generator writes into `Tests/<Module>Tests/` by default, and an optional argument gives another
output directory. To check that a generator still reproduces the committed tests, write to a
temporary directory and compare:

```sh
$UV --with rustworkx==0.18.1 python3 Tests/Catalogs/ColoringModule/swiftgen.py /tmp/co
for f in /tmp/co/*; do cmp "$f" Tests/ColoringModuleTests/"$(basename "$f")"; done
```

| Catalog | Extra pins | Regenerate the tests | Self-check |
|---|---|---|---|
| BipartiteGraphs | — | `swiftgen.py` | `ref.py` |
| Centrality | scipy | `gen.py` (all 10 files, including the precondition file) | `ref.py` |
| Cliques | — | `gen.py` | `ref.py`; `conf_vals.py` prints the conformance literals |
| ColoringModule | rustworkx | `swiftgen.py` | `ref.py --stress` |
| CommunityDetection | scipy | `swiftgen.py` | `ref.py`; `gen.py && ref.py --fill` rebuilds `cases.md` from `cases.head.md` (overwrites it) |
| Connectivity/undirected | — | `gen_tests.py` (§A – §G) | `ref.py`; `gen_collapsed.py` prints CN-341's rows |
| Connectivity/directed | — | none: tests written by hand from the printed values | `check.py`; `doms.py` needs `BOOST_GRAPH=<boostorg/graph checkout>` |
| Covering | igraph | `swiftgen.py` | `ref.py --stress`; `PYTHONHASHSEED=0 ref.py --write` reproduces `cases.md` exactly (CV-124's note follows the hash seed) |
| Cycles | igraph (for `ref.py`) | `gen.py` (also assembles `CycleRepresentationTests.swift`) | `ref.py` (about 2 minutes) |
| Distances | scipy | `gen.py` | `ref.py` (reads `../TreeAlgorithms/cases.md`) |
| MatchingModule | scipy | `swiftgen.py` | `ref.py --stress` |
| Multigraphs | — | `swiftgen.py` | `ref.py` |
| Traversal | none (stdlib) | `gen.py` (`SearchTranscriptTests.swift`) | `check.py`; `dump.py`, `compact.py` reproduce `dump.txt`, `compact.txt` |
| Trees | — | none | `ref.py`; `extras.py` |
| TreeAlgorithms | — | none | `ref.py`; `extra.py`, `extra2.py`, `extra3.py` |
| Walks | — | none | `ref.py` |
| SpanningTrees | scipy | none | `ref.py` |
| ShortestPaths | — | none | `cases.py`, `cases_astar.py`, `cases_bf.py`, `bfcheck.py` reproduce their `.out` files; `check.py` |
| DisjointSet | scipy | none | `cases.py` reproduces `cases.out`; `check.py`, `rules.py` |
| PriorityQueue | none (stdlib) | none | `ref.py` reproduces `cases.out` |
| CompressedSparseRow | none (stdlib) | none | `fixtures.py` prints the fixture arrays |
| GraphProtocols | — | none | `directed_calc.py`, `undirected_calc*.py`, `verify.py` (also covers UndirectedAdjacencyList) |
| AdjacencyList, AdjacencyMatrix, EdgeList | — | none: catalog only | — |

"None" under Regenerate means the suite was written by hand from the catalog. Files the
generators do not write (property, stress, review and most precondition tests) are hand-written
too. Their literals come from the scripts listed.

When a catalog changes, regenerate, compare with `git diff`, and run the suite
(`bazel test //Tests/<Module>Tests`). Keep catalogs here, never only in a scratch directory.
