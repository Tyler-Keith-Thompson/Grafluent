# Fuzzing

Coverage-guided fuzz targets for [libFuzzer](https://llvm.org/docs/LibFuzzer.html), one per
component, in their own package so the library never links the fuzzer runtime.

| Target | Checks against |
|---|---|
| `FuzzPriorityQueue` | A dictionary from index to priority: every query after every operation; a snapshot drains in order |
| `FuzzDisjointSet` | A naive label array: union results, `find`, `inSameSet`, `setSize`, `setCount`, canonical `labels()`, equality with a rebuilt value |
| `FuzzAdjacencyList` | Sets of vertices and pairs: neighborhoods, degrees, dense vertex and edge indices, edge positions, equality and hashing, snapshots |
| `FuzzUndirectedAdjacencyList` | The same for unordered pairs, with self-loops listed twice and each position at both ends |
| `FuzzShortestPaths` | Floyd–Warshall: Dijkstra on two representations, single target, A*, unweighted, Bellman–Ford, the negative-cycle witness, undirected Dijkstra |

Each target reads its input as a sequence of small choices (`FuzzInput`): an operation and its
arguments, or a graph's size, edges and weights. Every byte string decodes, and a mutation of one
byte changes one choice, so libFuzzer explores operation sequences rather than parse errors.

## Running

| Command | Does |
|---|---|
| `just fuzz` | Every target for 60 s, all at once, splitting the cores between them |
| `just fuzz FuzzShortestPaths -t 600 -j 16` | One target for 10 minutes on 16 workers |
| `just fuzz-regress` | Replays every corpus once (seconds); run after changing a fuzzed module |
| `just fuzz-repro <target> <crash file>` | Replays a crash and writes a minimized copy beside it |

A run is bounded by wall time. New inputs that add coverage are merged into `Fuzz/Corpus/<target>/`
(local, not committed), so the next run resumes from there. Crashes are written to
`Fuzz/Crashes/<target>/`; each one becomes a test in the module's suite, and then the file is
deleted.

## Toolchain

Xcode's toolchain does not include the libFuzzer runtime (`libclang_rt.fuzzer_osx.a`); the
swift.org toolchains do. The scripts build with `swiftly run swift build +6.3.3` (override with
`GRAFLUENT_FUZZ_SWIFT`), so install it once with `swiftly install 6.3.3`. The build prints
`unknown argument: '-target-arch-variant'` while reading the newer SDK's interfaces, then falls
back and succeeds; the scripts hide it.

Targets are built in release mode with AddressSanitizer: preconditions stay on, and the unsafe
buffer code in the representations and the heap is checked for out-of-bounds access.

SwiftPM links each executable against its own `main`, which conflicts with libFuzzer's, so each
target has an `@main` that calls `runFuzzer`, which starts libFuzzer through
`LLVMFuzzerRunDriver`.

## Adding a target

Add `Sources/Fuzz<Name>/Fuzz<Name>.swift` with an `@main` enum calling `runFuzzer`, and a line in
`Package.swift`. Check against a model simple enough to be obviously right, check after every
operation, keep values small (vertices 0..<10, priorities 0..<8) so collisions and ties are common,
and include a snapshot copy to catch copy-on-write bugs.
