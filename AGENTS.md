# Grafluent: notes for coding agents

Grafluent is a generic graph library for Swift 6.4 (minimum). Performance comes first: generic
code must run at the speed of a hand-written loop over arrays. Bazel is the development build;
SwiftPM is the published package. `README.md` is the user-facing overview.

## Layout

```
Sources/<Module>/              One directory per module, each with a generated BUILD.bazel
Sources/Grafluent/             Umbrella module (@_exported imports) and the landing DocC catalog
Tests/<Module>Tests/           One test target per module; Performance/ holds speed-reliant tests
Tests/GrafluentTests/          The README examples, verbatim
Tests/GrafluentTestSupport/    Shared test fixtures and test vertex types (data only)
Tests/Catalogs/<Module>/       Case catalogs, reference models and test generators (not compiled)
Benchmarks/                    Separate SwiftPM package (ordo-one/benchmark), generated from BENCHMARKS;
                               Bazel only caches its simulated counts (Benchmarks/BUILD.bazel)
Differential/                  Differential-testing harness, driven by scripts/differential.py
Fuzz/                          libFuzzer targets, driven by scripts/fuzz.py
Explore/                       Browser explorer: Grafluent as WebAssembly with ElementaryUI (`just explore`)
scripts/modules.py             The module graph
scripts/mutants/<Module>.py    Hand-written mutants for `just mutate`
tools/                         Bazel rule wrappers (warnings as errors, Swift 6 mode), DocC rules;
                               tools/bazel turns BuildBuddy on when the Keychain holds its key, and
                               on macOS sweeps stale output bases once a day (tools/sweep-output-bases):
                               a deleted workspace's, or one idle 7 days
```

### Module graph

`scripts/modules.py` is the source of truth for modules, their dependencies, test targets,
external packages and platforms. `just modules` regenerates `Package.swift`, every `BUILD.bazel`,
the umbrella `Grafluent.swift`, the Differential manifests and the Benchmarks package's
`Package.swift` and `BUILD.bazel` from it. Never edit the generated
files by hand; `//:package_swift_test` fails when `Package.swift` disagrees with the Bazel graph.
`just modules` refuses a table or function defined twice in it, which a template update can merge
in beside the project's own: keep one definition, holding the project's rows, and delete the other.

- Add a module: a row in `MODULES` (name, group, description, dependencies), then `just modules`.
- Add a test target: a row in `TEST_TARGETS`. A target with a `Performance/` directory of Swift
  sources must be listed in `PERFORMANCE_TESTS`, and the reverse.
- Run a test target in the iOS simulator as well (the tests of a module every platform builds that
  holds code under `#if canImport(UIKit)`): its name in `SIMULATOR_TESTS`, then `just modules`. It
  stays in Package.swift and keeps its run on the Mac and Linux, and gains
  `//Tests/<Target>:<Target>Simulator`, an `ios_unit_test` of the same tests inside
  `tools/test_host`, which `just test` runs on a Mac and Linux skips. Its UIKit tests sit under
  `#if canImport(UIKit)`, and its exit tests under `#if !os(iOS)`, as iOS has none. At least one
  test must run on the Mac, since Bazel's runner fails a run of none; a target whose Mac tests are
  Apple's alone goes in `APPLE_ONLY_TESTS` too. A target that depends on an iOS module or a Bazel
  label runs in the simulator alone already, so it isn't listed.
  It needs the test host and the simulator settings in `.bazelrc`, which the app type and the
  `--simulator` and `--ios` options ship (`just modules` refuses the table without them).
  From the project template's checkout, `./template.py add <project> --simulator` brings them
  without an app.
  `just mutate` runs a spec's simulator targets through Bazel (`scripts/mutate.py`).
- Add an iOS app to this project: from the project template's checkout,
  `./template.py add <project> --ios` (after `just template-update`, if the stamp predates the
  option). It brings `Apps/Grafluent`, the test host, the simulator settings and `tools/ios.bzl`;
  until then `just modules` refuses `IOS_MODULES` and simulator tests.
- Give a test target an environment variable under `bazel test` (an integration test that runs
  only when `TEST_DATABASE_URL` is set, say): its name and the variables in `TEST_ENVIRONMENT`
  (`{"<Target>Tests": ["TEST_DATABASE_URL"]}`), then `just modules`. Bazel strips the test
  environment; the generator writes the names as `env_inherit` on that target's `swift_test`, its
  Performance one and its simulator `ios_unit_test`, so only those targets see the variable and
  only their cached results depend on it. Not `--test_env` in `.bazelrc`, which hands it to every
  test. SwiftPM passes the whole environment already. `check()` refuses a name that isn't a test
  target.
- Add an executable: a row in `EXECUTABLES` (name, description, dependencies). It holds only
  `@main`; its code lives in a module, where tests reach it.
- Add an example module (a demo app's views, a sample server's routes): a row in `MODULES` and its
  name in `EXAMPLE_MODULES`, then `just modules`. It builds and tests like any module, but has no
  library product, umbrella import or DocC archive, so neither it nor its dependencies ship. Only
  executables, test targets and other example modules may depend on it (`check()` enforces it).
- Offer a module on its own but not through `import Grafluent` (a test-support back end, such as
  an in-memory store adopters use in their tests): its name in `NON_UMBRELLA_MODULES` too, then
  `just modules`. It keeps its library product and DocC archive; only the umbrella leaves it out.
  The umbrella catalog's topic list is hand-written: list it there under a heading of its own, not
  among the production modules.
- A library module that imports Swift Testing (a helper adopters add to their test targets: a
  custom `Trait`, an assertion that records an `Issue`): its name in `TESTING_MODULES` and
  `NON_UMBRELLA_MODULES` too, then `just modules`. Bazel finds Testing only on the developer search
  paths, which rules_swift gives testonly targets alone; the generator gives them to its
  `swift_library` and its docs' symbol graph. A module that depends on it must be listed too, and no
  executable may (`check()` enforces both).
- Give a module resources (data files, Apple's privacy manifest): put them under `Sources/<Module>/`
  and list each in `RESOURCES` (`{"<Module>": [("process", "Data/x.json"), ("copy", "Fixtures")]}`,
  paths relative to the module, rules as SwiftPM's `.process` and `.copy`), then `just modules`.
  Package.swift gets `resources:`, and Bazel the same `Grafluent_<Module>.bundle`
  (`tools/resources.bzl`): nested in an app's or test bundle's resources on Apple platforms, in the
  runfiles of `bazel test` and `bazel run` on macOS and Linux, found by a generated `Bundle.module`.
  The module reads them through `Bundle.module` under either build system, and its tests read them
  through the module. Bazel processes `process` files only inside Apple bundles (strings, asset
  catalogs); elsewhere they are copied as they are, as SwiftPM does off Apple platforms. A module
  that calls a required-reason API or collects data ships `PrivacyInfo.xcprivacy`, listed as
  `("copy", "PrivacyInfo.xcprivacy")` so it sits at the bundle's root; `check()` refuses one left
  out, a listed path that doesn't exist, and one inside another listed directory.
- Give a test target fixture files (JSON to compare byte for byte, a sample input): put them under
  `Tests/<Target>/` and list them in `RESOURCES` under the target's name
  (`{"<Target>": [("copy", "Fixtures")]}`, paths relative to `Tests/<Target>`), then `just modules`.
  The target gets its own `Grafluent_<Target>.bundle` the same way, in its swift_test, its
  simulator ios_unit_test and its SwiftPM test target, and its tests read the files through
  `Bundle.module`. Not under `Performance/`, which the target leaves out: the speed-reliant tests
  of a `PERFORMANCE_TESTS` target list theirs under `<X>PerformanceTests`, paths relative to
  `Tests/<X>/Performance`, and read them through `Bundle.module` in debug and release alike.
- Generate a Swift source at build time (overloads for each arity, tables from a data file): the
  generator is a Bazel executable that writes the source to standard output, or, given output
  names, gets their paths before a `--`. List it in `GENERATED_SOURCES` under the module or test
  target (`{"<Module>": [("<Name>", "//tools/<generator>", [<input labels>], [])]}`), create an
  empty `Generated/<Name>.swift` in the target's directory, then `just modules` and `just sources`.
  Bazel compiles the generator's output; SwiftPM compiles the copy under `Generated/`, which
  `just sources` rewrites and `<Name>_test` fails on while it differs from what the generator
  writes. Commit the copy, and run `just sources` after a change to the generator or its inputs.
  `check()` refuses a copy that doesn't exist, and a speed-reliant, iOS or firmware target.
  Simulated benchmarks measure the generator's output, at the copy's path.
- Add a macro: its compiler plugin is a row in `MACROS` (name, group, description, and only
  package products as dependencies: swift-syntax's, with `swift-syntax` in `PACKAGES`), its sources
  in `Sources/<Plugin>/` (an `@main` `CompilerPlugin` listing the macro types), then `just modules`
  and `just resolve`. The module that declares the macros (`#externalMacro(module: "<Plugin>",
  type: ...)`) lists the plugin among its dependencies: Package.swift gets a `.macro` target, Bazel
  a `swift_compiler_plugin` in that module's `plugins`. The plugin has no product, docs or umbrella
  import; adopters import the declaring module, and build swift-syntax with it, so when the package
  has an umbrella, consider `NON_UMBRELLA_MODULES` for it. A test target that lists the plugin tests
  its expansions (`assertMacroExpansion` from `SwiftSyntaxMacrosGenericTestSupport`, with
  `Issue.record` as its failure handler); one that lists the declaring module tests the expanded
  code. A source that must not compile (a macro's diagnostic as the compiler reports it) is a
  `swift_compile_failure_test` (`tools/compile_failure_test.bzl`) in `Tests/CompileFailures`, a
  hand-written BUILD.bazel no Package.swift target holds, with a control that compiles.
  A plugin takes planted bugs like a module (`scripts/mutants/<Plugin>.py`), with its expansion
  tests as the spec's `TESTS`.
- Add a command plugin (`swift package <verb>`): a row in `PLUGINS` (name, verb, description, and
  the reason it writes to the package directory, or `None` when it writes nothing there), its
  sources in `Plugins/<name>/` (an `@main` `CommandPlugin`), then `just modules`. Package.swift gets
  a `.plugin` target and product; Bazel builds none of it, so no test reaches the plugin. Keep it
  thin, its logic in a module or an executable it builds and runs, and run it on the package
  (`swift package --allow-writing-to-package-directory <verb>`) after a change to it.
- Add an external package: a row in `PACKAGES`, its `swiftpkg_<identity>` repository in
  `MODULE.bazel`'s `use_repo`, then `just modules` and `just resolve`.
- A package only Apple platforms build (Objective-C, a wrapper of an Apple framework) goes in
  `APPLE_ONLY_PACKAGES` too: its products are linked on Apple platforms only, so the targets still
  build on Linux, and the code that uses them sits under `#if canImport(...)`.
- Add a benchmark target: a row in `BENCHMARKS` (name, what it imports), then `just modules`.
- A package that builds everywhere but WebAssembly (one on NIOPosix: Hummingbird, Vapor) goes in
  `NON_WASI_PACKAGES` too: its products are linked on every other platform, so the package still
  builds for wasm32-wasi, and the code that uses them sits under `#if canImport(...)`.
- Raise the Swift floor (a dependency's manifest needs a newer Swift): set `SWIFT` (every
  manifest's tools version, CI's and the Docker image's Swift, the minimum the docs state) and
  `SWIFT_TOOLCHAIN` (the swift.org release swiftly installs where Xcode's toolchain falls short)
  in `scripts/modules.py`, then `just modules`. It writes them into the generated manifests and
  replaces the previous ones in every other file that names them (`SWIFT_SITES`), from the record
  in `tools/swift_version.bzl`. Never edit a version in those files by hand. `just template-update`
  keeps the project's versions, and says when the template's have passed them.
  The fuzz targets build with `SWIFT_TOOLCHAIN`.
  `just wasi-test` builds with `SWIFT_TOOLCHAIN` and its WebAssembly SDK.
  The explorer builds with `SWIFT_TOOLCHAIN` and its WebAssembly SDK.
  CI needs a `swift-bazel` image of the new version, published from the project template's
  `ci-image/build.sh`; with the explorer, `just modules` asks for docc.yml's `WASM_SDK_SHA256`.
- A module name takes a `Module` suffix only when it would otherwise equal its main type's name
  (`AdjacencyListModule` holds `AdjacencyList`). No catch-all modules ("Core", "Utilities").

Module groups: Vocabulary (`GraphProtocols`, `Walks`, `Semirings`), Data structures
(`PriorityQueueModule`, `DisjointSetModule`, `LinkCutTreeModule`), Representations, Structures, Operations
(`GraphOperations`, `GraphProducts`), Algorithms, Generators (`NamedGraphs`, `RandomGraphs`),
Drawing and formats (`GraphDrawing`, `GraphFormats`). The README's module table lists them all.

## Commands

Every shell command gets a timeout. macOS has no `timeout`; use
`perl -e 'alarm 1800; exec @ARGV' <command>`. A planted bug can make an algorithm loop forever.

| Command | Does |
|---|---|
| `just build` / `just test` | Build / test everything (debug) |
| `bazel test //Tests/XTests` | One test target (`just test-one //Tests/XTests`) |
| `just filter <pattern>` | Tests whose name matches |
| `just test-release` | `--config=release`: builds and runs only the `XPerformanceTests` targets |
| `just spm-test`, `just verify` | SwiftPM tests; both build systems |
| `just modules` | Regenerate build files from `scripts/modules.py` |
| `just mutate <Module> [--all]` | Mutation testing from `scripts/mutants/<Module>.py`: every planted bug must be caught; reports survivors |
| `just fuzz [Target] [-t secs]` | Time-boxed libFuzzer runs (60 s per target); `just fuzz-regress` replays corpora, `just fuzz-repro <target> <file>` a crash |
| `just diff [--module X] [--cases N] [--seed S]` | Differential tests against NetworkX, scipy, rustworkx and igraph (pinned, through `uv`) |
| `just sources` | Rewrite the checked-in copies of generated sources (`GENERATED_SOURCES`) that SwiftPM compiles |
| `just resolve` | Re-resolve Bazel's SwiftPM dependencies after editing `PACKAGES` |
| `just bench [--target X]` | Benchmarks; `just bench-compare` against the `main` baseline |
| `just bench-simulated-compare [--target X]` | Simulated counts (Callgrind in a Linux VM, from `~/workspace/BenchmarkHarness`) against the committed `simulated` baseline; `just bench-simulated [--target X]` re-records it. Both measure only targets whose code changed |
| `just explore` | The browser explorer as release WebAssembly into `Explore/dist/`; the DocC workflow publishes it at `<pages>/explore/` |
| `just wasi-test [-c release] [--targets X,Y]` | SwiftPM tests on wasm32-wasi under wasmtime: a 32-bit `Int` |
| `just docs` | Combined DocC site into `.build/docs` |
| `just generate` | Xcode project from the Bazel graph, in `xcode/` (out of the root, where `xcodebuild` would pick it over `Package.swift`) |
| `just buildbuddy-key`, `just ci-secrets` | Store the BuildBuddy key in the Keychain (once per Mac; builds then use the remote cache); set it as this repository's Actions secret with `gh` |
| `just template-update` | Merge the project template's changes since `.template.json`'s commit; resolve conflicts, then `just modules`, `just test` |
| `bazel query 'rdeps(//Tests/..., //Sources/X)'` | Test targets affected by a change to X |

- Debug is the default configuration. Every test target except the `XPerformanceTests` ones is
  tagged `debug-only`, which `--config=release` filters out.
- A test that bounds wall-clock time, or runs a large input under `.timeLimit`, belongs in
  `Tests/X/Performance/`.
- Release builds use their own output base (see the justfile). Don't create other output bases
  or copies of the repo, and shut down any extra Bazel server you start.
- Run suites through Bazel, not `swift test --filter`. Only `mutate.py` builds inside
  `.build/mutation`.
- First-party warnings are errors (`tools/swift_rules.bzl`); dependencies build quietly. Fix the
  warning, never suppress it. DocC's are too: `just docs` fails on a link that doesn't resolve.
- CI's Bazel jobs run in `ghcr.io/tyler-keith-thompson/swift-bazel:<swift>-<bazel>`, Swift with
  the Bazel in `.bazelversion` already in it, built by the project template's `ci-image/build.sh`.
  Changing `.bazelversion` or the workflows' Swift version means a new tag from there.
  The package is private; a repository pulls it once added under its Manage Actions access.
- Exit tests (`#expect(processExitsWith:)`) go in files of their own, apart from the other tests:
  builds for platforms that cannot start a child process leave those files out.

### 32-bit `Int` (WebAssembly)

watchOS's arm64_32 and wasm32 have a 32-bit `Int`. `just wasi-test` (`scripts/wasi_test.py`)
builds the SwiftPM test targets with `swift build --build-tests --swift-sdk
swift-6.4.3-RELEASE_wasm` through swiftly into `.build/wasm`, then runs each test binary (one
`<Target>-test-runner.wasm` per target, or an older toolchain's one `GrafluentPackageTests.xctest`)
with `wasmtime run --dir . --dir <checkout>::<checkout> --argv0 <binary's path> <binary>
--testing-library swift-testing`, logs in `.build/wasm/logs`. The checkout at its own path and the
binary's path as `argv[0]` are where SwiftPM's `Bundle.module` looks for a module's resource bundle
(an absolute build path with the `.xctest`, beside `Bundle.main` with the per-target runners, which
WASI's Foundation takes from `argv[0]`). `-c release` builds with `-enable-testing`, so suites that
`@testable import` build in release too. A `--targets` name that isn't a test target is refused
before anything builds, and a group fails when its build wrote no runner for one of its targets.
Needs swiftly's 6.4.3 toolchain, its WebAssembly SDK (`swift sdk list`; the install command is in
`Explore/README.md`) and `brew install wasmtime`. If the toolchain crashes on the manifest against a
newer Xcode's SDK, pass `--xcode /Applications/Xcode-26.2.0.app` (as `EXPLORE_XCODE` does for
`just explore`).

- One binary of every target can pass wasmtime's limit of a million functions, so targets run in
  groups (`GRAFLUENT_WASI_TESTS` makes `Package.swift` declare only those).
- Not run on WASI: files with exit tests (no child processes; the manifest leaves them out) and
  anything needing threads, such as the `*MapConcurrencyTests` (`#if !os(WASI)`).
- WASI runs every task on one thread, and a sleep that is cancelled still holds it until its
  deadline. A time limit's timer is such a sleep: the body runs, but the timer then holds the
  thread for the whole limit, so every `.timeLimit` test reports its limit exceeded. The script
  counts only the issues besides those. Tests run in parallel, so the timers overlap; `--serial`
  (Swift Testing's `--no-parallel`) costs each time-limited test its whole limit. A test that
  cancels a real-clock sleep waits it out the same way.
- Without wasm tail calls, an await that doesn't suspend deepens both stacks. The script links a
  64 MB stack and gives wasmtime a 256 MB one, enough for a 10,000-deep chain of such awaits; a
  deeper one traps or hangs on WASI alone.
- Foundation on WASI drops the last character of a resource's file name when the lookup names a
  subdirectory: `Bundle.module.url(forResource: "sample", withExtension: "txt", subdirectory:
  "Fixtures")` returns `Fixtures/sample.tx`, which doesn't exist, and so do
  `path(forResource:ofType:inDirectory:)`, `urls(forResourcesWithExtension:subdirectory:)` and a
  name holding the directory. Look up the directory itself, then append the file:
  `Bundle.module.url(forResource: "Fixtures", withExtension: nil)?.appending(path: "sample.txt")`.
- A dependency that doesn't build for WASI (NIOPosix and what sits on it) fails the whole build.
  List its package in `NON_WASI_PACKAGES` (see "Module graph"), and put the code and tests that
  use it under `#if canImport(<its module>)`.
- Swift 6.4.3 for WebAssembly passes a non-throwing method reference (`apply: op.apply`) as a
  `throws(E)` closure argument without converting it, and the call traps with "indirect call
  type mismatch" in debug and release alike; natively nothing shows. Pass a closure literal,
  `{ (x, y) throws(E) in op.apply(x, y) }`, as SpectralGraphTheory's Lanczos callers do.
- A test whose literals need a 64-bit `Int` sits inside `#if _pointerBitWidth(_64)`; the catalog
  generators add that guard themselves.
- Write width-dependent bounds as comparisons on `Int64` or `Int.max`, never `1 << 32` on an
  `Int` (it is 0 at 32 bits); keep counts that grow as n² or n³ in `Int64`.

### Mutation, fuzzing and differential testing

- `just mutate X` re-runs only mutants whose code or tests changed (`--all` runs every one).
  Fix each survivor with a test, or prove it equivalent and remove it with a note in the spec
  file's header. A mutant that edits a comment survives silently; `nth=` counts comment matches.
  A `stmt` mutant can't replace a `defer` (in the else block it would run when that block ends,
  changing the unmutated build): mutate the statements inside it. Each test binary runs in an
  empty directory of its own, so a mutant that turns an absolute path relative writes nowhere in
  the checkout.
- Each module has a fuzz target in `Fuzz/`, a SwiftPM package Bazel ignores, built with the
  swift.org toolchain through swiftly (`swiftly install 6.4.3`; `Fuzz/README.md`). A crash becomes
  a regression test, then its file is deleted.
- `just diff` compares only answers that ties cannot change and validates returned paths and
  witnesses.

### Catalogs

`Tests/Catalogs/<Module>/` holds `cases.md` (case IDs, inputs, expected values), `api.md` (the API
the tests were written against), `ref.py` (an independent Python reference model that re-checks
every row; `ref.py --write` regenerates `cases.md` where supported) and `swiftgen.py` or `gen.py`
(writes the catalog-row Swift tests). Generated test files must match the generator byte for
byte: edit the generator, regenerate, `git diff`, then run the suite. `Tests/Catalogs/README.md`
lists each catalog's scripts and Python pins (run through `uv`).

## Workflow

### Adding a feature

A feature is done when it has all of these. Copy what its sibling features in the module already
have.

1. **Code and docs.** The implementation, with doc comments per "Docs" below. A new module gets a
   row in `scripts/modules.py`, then `just modules`, the README's module table and the umbrella
   DocC catalog's topic list (``` ``/Module`` ```: a link to another module needs the slash).
2. **Tests** in `Tests/<Module>Tests`:
   - hand-worked cases;
   - edge cases: empty graph, one vertex, self-loops, parallel edges where the representation
     allows them, disconnected graphs;
   - `checked:` spellings and their errors;
   - exit tests for every trap;
   - a property test against a naive reference;
   - the same checks run on several representations (`AdjacencyList`, `CompressedSparseRow`,
     `AdjacencyMatrix`, the pseudographs, `StableDirectedGraph` with holes).
3. **Catalog rows**, if `Tests/Catalogs/<Module>/` exists: `ref.py` checks every row, and the
   generator regenerates its test files byte for byte.
4. **Mutants** in `scripts/mutants/<Module>.py`. Run `just mutate <Module>` and kill every
   survivor or document it as equivalent in the spec header.
5. **A differential comparison** in `just diff`, where NetworkX, igraph, scipy or rustworkx has the
   function. A failure becomes a test, then its file is deleted.
6. **Fuzzing:** extend `Fuzz/Sources/Fuzz<Module>` with invariant checks, then run
   `just fuzz <Target> -t 60` and `just fuzz-regress`.
7. **A benchmark** in `Benchmarks/Benchmarks/<Module>Benchmarks` (a row in `BENCHMARKS`, then
   `just modules`), starting with a `BASELINE` entry: the hand-written loop over arrays the code
   must keep pace with. Measure in release, and add a ratio test in
   `Tests/<Module>Tests/Performance/` where siblings have one. Use small inputs in debug builds,
   because the timing only runs in release and CI's debug runner is slow.
   Judge a speed change by `just bench-simulated-compare --target <Module>Benchmarks`: its
   instruction, cache-miss and branch counts don't move when the machine is busy, as wall clock
   does. The baseline also carries the benchmarks' allocation and retain counts; absolute times
   still come from `just bench`. Re-record the `simulated` baseline for the targets a change
   touches (`just bench-simulated --target X`) and commit it with the change. Its `results.json` is
   pretty-printed with sorted keys, one benchmark's entry on lines of its own, and a benchmark
   whose instruction and malloc counts moved less than compare's 5% threshold keeps its recorded
   entry. So the file changes only where a benchmark did, and branches that change different
   benchmarks of one target merge without a conflict. Resolve a conflict by re-recording after
   the merge, never by hand. A benchmark whose mallocs drop to zero, or that was measured over a
   different number of iterations, counts as moved. Harness options (`--iterations`, `--filter`)
   measure uncached and write the same format, keeping the entries that didn't move. To rewrite
   every entry (a change aimed at cache misses alone), delete the file first.
8. **A `graph.lazy` member**, if the algorithm has steps worth watching (see "Shapes"), with a
   replay test showing its events reproduce the plain call.
9. **An explore page**, optional. See `Explore/README.md` for the page order, compare tables,
   first frames and the owner's copy rules.

Watch for these:

- A closure inside `#expect` nested in another closure can run the wrong body, or crash the
  Linux compiler. Put the body in a nested `func`.
- Hoist literals to typed `let`s rather than writing them inline in `#expect`.
- Iterate dictionary keys sorted wherever order is visible.
- `Package.swift` must stay free of Foundation, because the fuzz builds use the swift.org
  toolchain.

### What to run

| Change | Run |
|---|---|
| Any library code | `bazel test` for every target in `bazel query 'rdeps(//Tests/..., //Sources/X)'`, then `just test-release` |
| A module's code or tests | `just mutate X`; `just fuzz-regress` for its targets; `just diff --module X` if it has a section |
| Code using `Int` arithmetic that could overflow, or anything platform-conditional | `just wasi-test -c release --targets XTests` (a 32-bit `Int`) |
| `Benchmarks/`, or an API the benchmarks call | `cd Benchmarks && env -u TOOLCHAINS xcrun --toolchain default swift build -c release` |
| `Explore/` | `EXPLORE_XCODE=/Applications/Xcode-26.2.0.app just explore`, then check the pages in headless Chrome at 1280 and 400 px |

### Pushing

Push finished work to `main` yourself; don't wait to be asked, and never end a task with
finished commits unpushed. Every push to `main` releases a patch version, and CI minutes are
scarce, so push once per batch rather than once per commit: when the work the owner gave you is
done (the whole request, or Ready is empty when working the backlog), push everything it
produced together.

1. Verify the committed state in a clean worktree: `bazel test //...` in debug, then
   `--config=release`.
2. Run the same commit's debug suite on arm64 Linux. CI runs on `ubuntu-26.04-arm`, so this
   fills the remote cache CI reads.
3. Push, then watch the Release and DocC workflows to green, and fix anything that breaks.
4. Don't add CI steps that rebuild without the owner's approval.

## House rules

### Library code

- No Apple private API (`@_silgen_name`, undocumented runtime entry points). Apps using it are
  rejected from the App Store.
- No hooks or SPI added only for tests.
- Use swift-atomics (`ManagedAtomicLazyReference` and so on) or the standard library's
  `Atomic`/`Mutex` for shared state. No hand-rolled atomics.
- Names come from established graph libraries or the literature, familiar programmer terms
  first and the mathematical term when no common one exists. Never invent names. No synonym
  typealiases; one name per concept. Spell names out (`StableDirectedGraph`, not a short form).
- Delete unused API rather than keeping it.
- Small files, one main type each. Vocabulary a body needs goes in a `fileprivate` extension on
  the type it describes (`extension User { fileprivate func matches(_ term: String) -> Bool }`),
  so the body reads as a sentence.
- No datasets in the library. Generators are mathematical families only.

### Seams and composition (*default*)

How code that reaches past the process is split: networks, disks, clocks, other services. A pure
library with none of that can skip this section.

- **Layers with one job each.** A transport (HTTP, a file) knows nothing of the domain. A service
  built on it speaks one API. Persistence and features build on services. A module depends only
  on layers below it. Where two modules' models meet, an adapter in the module that imports both
  translates between them, rather than one importing the other. A few lines duplicated across
  modules cost less than coupling them; say so in a comment where it happens.
- **A protocol at every seam.** Anything a test must replace is a protocol marked `@Mockable`.
  Its production conformer is internal and takes the protocol's name with a leading underscore
  (`_SearchService`), so autocomplete offers the protocol. Beside it, a `Factory` on `Container`
  (DependencyInjection) returns it as the protocol, scoped on purpose: `.cached` for one instance
  that holds state, `.shared` for one instance while anyone holds it, unique otherwise. Callers
  resolve it with `@Injected`, `@LazyInjected` or `@ConstructorInjected`, never by naming the
  conformer.
- **The executable is the composition root.** Modules ship working defaults (an in-memory store);
  the executable registers what production swaps in (the store on disk) at startup.
- **Async work is a pipeline of values.** With Afluent, a call returns a lazy unit of work
  (`DeferredTask`, `AsynchronousUnitOfWork`) built from operators: `flatMap` to the next step,
  `tryMap` to validate, `decode`, `handleEvents` for side effects (caching, logging), `tryCatch`
  for a fallback, `shareFromCache` so simultaneous identical requests make one call. Nothing runs
  until `execute()`, so callers compose, retry and cancel it freely.
- **Time is a dependency.** Code that waits, debounces or times out takes a clock registered on
  `Container` (`AnyClock<Duration>`), never an inline `Task.sleep` or `ContinuousClock()`. Tests
  register a `TestClock` (swift-clocks) and advance it.
- **State is an enum of what can be true.** A screen, a response or a load is an enum with a case
  per state (`prompt`, `loading`, `results([User])`, `noResults(String)`, `failed`), mapped once
  from the outcome, not optionals and flags that can disagree.
- **Isolation states its reason.** Mutable state reached from async callers lives in an actor, or
  behind `Mutex` where the hops would cost too much; a comment says which and when to switch.
- **Literals checked at compile time.** A literal URL is `#URL("…")` (the URL macro), not
  `URL(string:)!`. A force unwrap or trap that remains has a comment proving it can't fire and
  why a crash beats a thrown error no caller could handle.
- **Logging.** A type that logs has one `private static let logger`: swift-log's
  `Logger(label: "<module>.<Type>")`, or `os.Logger(subsystem:category:)` in Apple-only code, where
  every interpolation of user data stays private. Levels mean something: `debug` for a path taken,
  `info` for a notable event, `notice` for a degraded result (cached data served), `error` for a
  failure. Cancellation is not a failure; don't log it as one. Logs are for developers; tests
  don't pin them.

### Tests

- Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`, `#require`). Never XCTest.
- Each test is self-contained and portable: no assertion or setup helpers, not DRY; a test
  copied to another file still works. Shared fixture data in `GrafluentTestSupport` is tolerated;
  shared assertions are not.
- Test names state the rule they pin ("successors(checked:) throws VertexNotFound for a missing vertex").
- **Sociable.** A test runs the real code under test and its real collaborators wherever they are
  fast and deterministic, and mocks only the seams that reach out (network, disk, clock) or that
  it must steer. Inside `withTestContainer { }`, `Container.x.useProduction()` resolves the real
  subject; its seams get mocks.
- **Shape.** Arrange; then act on `sut`; then assert, with a blank line between. Name the values
  `expected…` and `actual`. Where the call itself is the rule, `verify(mock)` pins it:
  `.called(.once)`, or `.called(.never)` for one that must not happen.
- **Deterministic concurrency.** Never sleep to let something happen. Order concurrent work with
  gates the test opens (a stub that awaits a `SingleValueSubject` the test sends), advance a
  `TestClock`, and run main-actor tests under `withMainSerialExecutor` (swift-concurrency-extras).
  A suite that awaits carries `.timeLimit(.minutes(1))`, so a hang fails rather than stalls.
- **Unhappy paths.** Every failure a seam can produce (a timeout, no network, a malformed
  response, a missing resource) has a test of what the caller sees.
- Tests may call underscored and `package` API.
- Property tests use swift-property-based (`import PropertyBased`, `propertyCheck`).
- Seeded tests and benchmarks seed SwiftPRNG's generators (`import Generators`,
  `Xoroshiro128Plus(seed:)`), never a hand-written one. Their draws stay the standard library's
  (`random(in:using:)`, `shuffled(using:)`) rather than SwiftPRNG's `uniform(in:)`,
  `integer(in:)` and `bernoulli(_:)`, because switching would change the catalog rows' expected
  values.

### Docs

- Describe the current API. No history ("previously", "renamed"), design debates, comparisons
  with other libraries, or benchmark numbers in doc comments or READMEs. Complexity bounds are
  fine. Algorithm authors are fine when they name the algorithm.
- Doc comments: a one-line summary, then parameters, return value, complexity, and what traps or
  throws.
- `//` comments say why, where the code makes a choice a reader would question: the data
  structure, an actor over a `Mutex`, deliberate duplication, a force unwrap, the package rejected
  and when it would become the right one. Doc comments describe the API; these record decisions. A
  comment that restates the code is deleted.
- The README is the front page: what the project is, how to install or run it, one short example,
  and links. Everything else (guides, every option, reference) goes in the DocC catalogs, which
  the README links to. When a section grows past a screen, move it out rather than trim the
  README's other sections to make room.
- Run prose docs through the `humanizer` skill (`/humanizer`) before committing them: READMEs, DocC
  articles, doc comments and this file. It removes the tells of generated text (inflated claims,
  stock phrases, forced lists of three) without changing what the text says. Docs only: not code,
  `//` comments, commit messages or backlog items.

### Git

- Commit message style: `[main] - <summary>`, no trailers (no co-author or session lines).
- One commit per finished feature or fix, after its suites pass.
- Never file bugs with third-party projects; record them locally.

## API conventions

### Errors

- **Plain spellings trap** on a missing vertex or edge, like an `Array` subscript. They are the
  fast path.
- **`checked:` spellings throw** a typed, payload-free error: `successors(checked: v)` throws
  `VertexNotFound`; `source(checkedEdgeAt: p)` throws `EdgeNotFound`; calls that can fail either
  way throw `ElementNotFound` (`.vertex`, `.edge`). Labels such as `path(checkedFrom:to:)` or
  `distance(checkedTo:)` mark which argument is checked. There are no nil-returning variants;
  `try?` gives `nil`. These live in `GraphProtocols/MembershipErrors.swift`.
- **Invariant-breaking mutations throw on the plain spelling** and change nothing:
  `AcyclicEdgeError` (`.cycle`, `.selfLoop`, `.missingEndpoint`), `LooplessEdgeError`
  (`.selfLoop`, `.missingEndpoint`), `BipartitionError` (`.sameSide`, `.onOtherSide`,
  `.missingEndpoint`), `LabelingError`. `insert(checked:)` reports a missing endpoint as a case
  of the same error, so one typed `catch` is exhaustive. Errors carry no vertex, because a vertex
  type need not be `Sendable`.
- **Iterative solvers throw `NoConvergence`** (`iterations`, `residual`) when they spend their
  iteration limit. Invalid parameters (tolerance ≤ 0) still trap.
- **Queries whose failure is the answer return a witness**, not an error: `findCycle() ->
  Cycle?`, `findOddCycle()`, `findNegativeCycle`, `topologicalSort() -> [Vertex]?`.

### Shapes

- `Graph` (undirected) and `DirectedGraph` are separate protocols; no type conforms to both.
  `graph.directedView` and `digraph.undirectedView` convert. Refinements:
  `BidirectionalDirectedGraph` (predecessors), `SparselyIndexedDirectedGraph` and its undirected
  counterpart `SparselyIndexedGraph` (positions with holes), `MutableDirectedGraph` (mutation hooks
  for wrappers). `Hypergraph` and
  `DirectedHypergraph` are separate again.
- A graph exposes collections (`vertices`, `edges`); it is not itself a `Sequence`. An edge is
  identified by its position (`Edges.Index`), which tells parallel edges apart.
- Lazy views end in `View` (`transposedView`, `undirectedView`, `complementView`,
  `inducedSubgraphView(on:)`, `cartesianProductView`). The materialized form shares the root:
  `transposed()`. Reversing every edge is "transposed", never "reversed" (which is the
  standard library's sequence reversal).
- Step-by-step algorithms live under `graph.lazy` (`LazyDirectedGraphView` / `LazyGraphView` in
  GraphProtocols; each algorithm module extends them), as `Sequence.lazy` does for `map`. Each
  member is named for the algorithm whose steps it reports and returns a sequence of `…Event`s:
  `lazy.breadthFirstSearch`, `lazy.depthFirstSearch` (vertex pairs),
  `lazy.edgeBreadthFirstSearch`, `lazy.edgeDepthFirstSearch` (edge positions), `lazy.dijkstra`,
  `lazy.aStar`, `lazy.bellmanFord`, `lazy.kruskal`, `lazy.prim`, `lazy.edmondsKarp`,
  `lazy.louvain`, `lazy.bronKerbosch`, `lazy.kahn`, `lazy.hopcroftKarp`, and on a
  `FunctionalGraph` `lazy.floydCycleDetection` and `lazy.brentCycleDetection`. With no graph to
  take `lazy` from, the stepper is a function of the input named the same way:
  `galeShapley(proposerPreferences:reviewerPreferences:)`. Events favour useful state over speed;
  their ratio tests only bound a pathological slowdown (3× the plain call).
- Results are dedicated types (`ShortestPathTree`, `Components`, `Matching`, `Flow`), not tuples.
  Walk-like results are `Walk`, `Trail`, `Path`, `Circuit`, `Cycle` (vertices plus edge positions).
- Materializing operations and generators are static factories on a target the caller picks:
  `CompressedSparseRow.complete(vertexCount: 5)`, `Target.lineGraph(of:)`.

### Weights and attached maps

- Algorithms take weights as a closure over edge positions, `weight: (Edges.Index) -> W`, called
  on demand and never stored. Shortest-path entry points also take a `SelectiveSemiring`.
- `PropertyGraph` representations own attached maps: `addEdgeMap(default:)`,
  `addVertexMap(default:)`, and `addEdgeMap(of: T.self)` for an `EdgeMap<T?>` defaulting to `nil`.
  Maps are total (every element has the default until set). Read and write with
  `graph[map, ofEdgeAt: p]` / `graph[map, of: v]`; a removed element traps there and throws from
  `graph[map, checkedEdgeAt: p]`. Every mutation keeps every map in step, swap-removes included.
- `values(of:)` is an O(1) snapshot that reads like an array; pass `{ w[$0] }` to an algorithm.
- `generation` changes with every structural mutation (map writes don't count). Derived
  structures such as `CompressedSparseRow(g)` record it (`isCurrent(for:)`).
- `GraphAdaptor` exposes `base`; maps read through an adaptor whose positions are its base's.
  `GraphDelegator` refines it for rule-adding wrappers (`Multigraph`, `DirectedMultigraph`,
  `BipartiteGraph`, `DirectedAcyclicGraph`): every read member forwards to the base by default,
  and the wrapper implements its mutations, attached-map management and map writes. The wrapped
  graph is stored in an internal `_base`, never settable from outside, so its rules cannot be
  bypassed. Views that reorient or filter must not use it.

### Performance patterns

- Public types are copy-on-write structs, `@frozen`, with `@usableFromInline` internals.
  Algorithms are `@inlinable`; parameters are `some` generics, never `any`.
- Copy-on-write: the uniqueness check is inlined and the reallocation slow path is
  `@inline(never)`. Bulk mutations check uniqueness once, outside the loop.
- Algorithms number vertices densely (`vertexIndex(of:)`) and run index-space loops over flat
  rows (`successorIndices(ofIndex:)`) and unsafe buffers; scratch storage avoids copy-on-write.
- Traps measured in this codebase: nested functions capturing mutable locals (boxed, retained per
  step); generic iterators stored in arrays (use integer cursors); reading a struct out of a class
  property (copies and retains); lazy maps capturing `self`; per-round work proportional to the
  whole graph instead of the piece. In compound conditions, test the predictable part first.
- Write overflow guards as comparisons (`x <= Int.max / 4`), not a discarded
  `multipliedReportingOverflow` result, which an optimized build has miscompiled.

## Terminology

| Grafluent | Meaning (mathematical term) |
|---|---|
| `DirectedEdge` (`source`, `target`) | Ordered pair (arc, with tail and head) |
| `UndirectedEdge` | Unordered pair; `==` and hashing are symmetric |
| self-loop, `isSelfLoop`, `hasSelfLoops` | Edge from a vertex to itself (loop) |
| `successors(of:)` / `predecessors(of:)` | Out-neighbors N⁺(v) / in-neighbors N⁻(v) |
| `neighbors(of:)` | Neighbors in an undirected graph, N(v); a self-loop is listed twice |
| `outDegree`, `inDegree`, `degree` | d⁺(v), d⁻(v), d(v); a self-loop counts 2 in `degree` |
| `vertexCount`, `edgeCount` | Order \|V\|, size \|E\| |
| `transposedView`, `transposed()` | Every edge reversed (converse, transpose) |
| `undirectedView` | Directions dropped (underlying graph) |
| `descendants(of:)`, `ancestors(of:)` | Reachable from / reaching v |
| `graph.lazy.…` | An algorithm run step by step, as a sequence of its events (BGL's visitor events) |
| `parent`, `children`, `root`, `depth(of:)`, `height` | Rooted-tree relations; depth counts edges to the root |
| `Arborescence` | Directed rooted tree, edges away from the root (out-tree) |
| `Branching`, `minimumSpanningArborescence` | Forest of arborescences; optimum branching / arborescence (Edmonds) |
| `SteinerTree`, `terminals:` | Tree connecting a vertex subset (Steiner tree), its required vertices |
| `bridges()`, `articulationPoints()` | Cut edges, cut vertices |
| `biconnectedComponents()` | Blocks |
| `biEdgeConnectedComponents()` | 2-edge-connected components |
| `nontrivialStronglyConnectedComponents()` | Strong components containing a cycle |
| `simpleCycles()` | Elementary circuits |
| `chordlessCycles()` | Induced cycles (no chord) |
| `minimumMeanCycle(weight:)` | Cycle of least mean weight (Karp) |
| `allSimplePaths(from:to:)` | Every path with no repeated vertex |
| `randomWalk(…returnParameter:inOutParameter:)` | node2vec's p and q |
| `lexicographicBreadthFirstSearch()`, `maximumCardinalitySearch()` | LexBFS, MCS vertex orderings |
| `isChordal`, `findHole()` | Chordal (triangulated) graph; a chordless cycle of length ≥ 4 |
| `perfectEliminationOrdering()` | Perfect elimination ordering (PEO) |
| `girth()` | Length of a shortest cycle |
| `shortestSimplePaths(from:to:)` | Simple paths in nondecreasing length; `prefix(k)` is the k shortest paths (Yen) |
| `MaxPlusSemiring`, `ViterbiSemiring` | (max, +), the arctic semiring; (max, ×) over probabilities |
| `isAcyclic` | Forest (undirected) or DAG (directed) |
| `maximalCliques()`, `maximumClique()` | Maximal / maximum cliques; clique number ω(G) |
| `coreNumbers()` | Core numbers; the greatest is the degeneracy |
| `trussNumbers()`, `kTruss(_:)` | Truss numbers (trussness); the k-truss, every edge in k − 2 triangles |
| `onionLayers()` | Onion decomposition (Hébert-Dufresne et al.) |
| `cliqueNumber(of:)` | Largest clique through a vertex (node clique number) |
| `kEdgeConnectedComponents(_:)`, `kEdgeConnectedSubgraphs(_:)` | Classes with local edge connectivity λ(u, v) ≥ k; maximal k-edge-connected induced subgraphs |
| `isDSeparator(_:between:and:)`, `moralGraph(of:)` | d-separation; the moral graph (parents married) |
| `transitivity()` | Global clustering coefficient |
| `effectiveGraphResistance()` | Kirchhoff index |
| `modularity(of:resolution:)` | Q, with resolution γ |
| `cosineSimilarity(of:and:)`, `diceCoefficient(of:and:)` | Salton index; Sørensen index (vertex-pair similarity over neighbor sets) |
| `left`, `right`, `side(of:)` | The two classes of a bipartite graph (V = L ∪ R) |
| `Matching`: maximal / maximum / perfect | Independent edge set |
| `linearSumAssignment` | Assignment problem |
| `Coloring`, `chromaticNumber()` | Proper vertex colouring, χ(G) |
| `EdgeColoring` | Proper edge colouring; fewest colours is χ′(G) |
| `subgraphIsomorphism(to:)` / `monomorphism(to:)` | Induced subgraph isomorphism / subgraph isomorphism |
| `vertexColor:`, `edgeColor:` | Classes an isomorphism must preserve |
| `optimalEditPath(to:)`, `graphEditDistance(to:)` | Least-cost edit path; graph edit distance (GED) |
| `Pseudograph` / `Multigraph` | Parallel edges with / without self-loops (directed: `Directed…`) |
| `edgeCount(between:and:)` | Multiplicity |
| `cycleBasis()` | Fundamental cycles (basis of the cycle space) |
| `chinesePostmanTour(weight:)`, `PostmanTour` | Chinese postman problem (route inspection); `duplicatedEdges` eulerize the graph |
| `dualGraph()` | Planar dual of an embedding (a vertex per face) |
| `capacity:`, `supply:` | c : E → ℝ≥0; b(v), positive sends |
| `Flow`, `Cut` | s–t flow; s–t cut (S, T) |
| `incidenceGraphView` | Bipartite incidence graph of a hypergraph (Levi graph) |
| `size(ofHyperedgeAt:)` | \|e\| |
| `sources(ofHyperedgeAt:)`, `targets(ofHyperedgeAt:)` | Tail T(e), head H(e) |
| `outHyperedges(of:)`, `inHyperedges(of:)` | Forward star FS(v), backward star BS(v) |
| `cliqueExpansion()` | 2-section |
| `bConnectedVertices(from:)`, `fConnectedVertices(to:)` | B- and F-connection (Gallo et al. 1993) |

## Representations and structures

Every representation is a copy-on-write value; `Equatable` compares vertex and edge sets (not
isomorphism, not insertion order), except `EdgeList`, whose order is part of its value.

| Type | What it is | Notes |
|---|---|---|
| `AdjacencyList<V>` | Directed, simple (self-loops allowed); out- and in-rows per vertex | O(1) expected `contains(edge:)`, `edges(from:to:)` (`edges(between:and:)` undirected) and edge removal; O(degree) vertex removal. Removals swap-remove, so positions may change. Bulk initializers lay rows out packed in slot order. `MutableDirectedGraph`, `PropertyGraph` |
| `UndirectedAdjacencyList<V>` | Undirected counterpart of `AdjacencyList` | `Graph`, `PropertyGraph` |
| `AdjacencyMatrix` | Directed on `0..<n`, n×n bit matrix | O(1) adjacency; rows are `BitSet`s; vertices appended (`appendVertex()`), never removed; edge positions are cells; edge maps are dense, n² values each |
| `CompressedSparseRow` | Directed on `0..<n`, offsets plus targets | Immutable (initializers only); edge positions `0..<m`; binary-search `contains(edge:)`; not bidirectional (`BidirectionalCompressedSparseRow` or `transposed()`) |
| `EliasFanoGraph` | Directed on `0..<n`, rows Elias–Fano coded (WebGraph's EFGraph) | Immutable; built from edges, any directed graph on `0..<n` or a `CompressedSparseRow`, whose edge positions it shares; a few bits per edge (`bitsPerEdge`); rows decode sequentially, so `contains(edge:)` and `target(ofEdgeAt:)` are O(out-degree); `PropertyGraph` with dense maps |
| `EdgeList<V>` | Ordered list of directed edges | A `RandomAccessCollection`/`MutableCollection`/`RangeReplaceableCollection`; queries are O(m) scans; not a `DirectedGraph` |
| `ImplicitDirectedGraph<Row>` | Directed on `0..<n`, successors from a closure | Never stored; not `Equatable`/`Sendable`; no attached maps |
| `PackedCompressedSparseRow<V>` | Mutable directed graph, simple, rows packed in slot order with spare cells (PCSR, Wheatman–Xu) | `AdjacencyList`'s API and position rules (swap-removes) over a packed memory array of rows: walks read the rows as compressed sparse rows, an insertion moves O(log² n) cells amortized; `contains(edge:)` O(1) expected; `MutableDirectedGraph`, `PropertyGraph` |
| `BidirectionalCompressedSparseRow` | `CompressedSparseRow` plus its column form | Immutable; `GraphDelegator` over the row form, same positions; `predecessors`, `inEdges` (positions) and `inDegree` in O(1); `transposed()` is O(1); about twice the memory |
| `LabeledGraph<Label, Base>` | `Hashable` labels over `CompressedSparseRow` or `AdjacencyMatrix` | Label `i` names base vertex `i`; index-space members are the base's; positions are the base's |
| `IncidenceMatrix` / `OrientedIncidenceMatrix` | Hypergraph incidence as bit planes | `Hypergraph` / `DirectedHypergraph` |
| `UndirectedIncidenceList<V>` / `IncidenceList<V>` | Hypergraphs as incidence lists | Hyperedges may be empty or repeated |
| `DirectedAcyclicGraph<Base>` | Wrapper over any `MutableDirectedGraph` (`AdjacencyList`, `DirectedPseudograph`, `StableDirectedGraph`) | Rejects cycle-closing edges with `AcyclicEdgeError`; maintains `topologicalOrder` (Pearce–Kelly); reads are the base's |
| `Tree`, `Forest` | Undirected; connected and acyclic / acyclic | Immutable; failable initializers from unchecked input |
| `RootedTree`, `Arborescence` | Rooted tree, undirected / directed away from the root | `parent`, `children`, `depth`, `preorder`; O(1) conversion between them |
| `OrderedTree` | Rooted tree whose child order is part of its value (plane tree) | Not a graph; O(1) conversion to and from `RootedTree` and `Arborescence`; `treeEditDistance` (Zhang–Shasha) in TreeAlgorithms |
| `BinaryTree` | Rooted tree with positional left and right children | Not a graph; O(1) conversion to `OrderedTree` (left first) and `Arborescence`; `inorder`; `allBinaryTrees(vertexCount:)` (Algorithm B), `huffman(weights:)` |
| `PrefixTree<Symbol>` | `prefixTree(of:)`: the trie of some sequences | An `Arborescence<Int>` (root 0, edge into v at position v − 1), `symbol(ofEdgeAt:)`, `sequenceEnds`, `isSequenceEnd(_:)` |
| `BipartiteGraph<V>` | Undirected, simple, every edge crosses L–R | Throws `BipartitionError`; a `GraphDelegator` over `UndirectedAdjacencyList` |
| `Pseudograph<V>` / `DirectedPseudograph<V>` | Parallel edges and self-loops | `insert(edge:)` returns the new edge's position |
| `Multigraph<V>` / `DirectedMultigraph<V>` | Parallel edges, no self-loops | Throw `LooplessEdgeError`; `GraphDelegator`s of the pseudographs |
| `StableDirectedGraph<V>` | Directed pseudograph whose positions survive removals | Positions never reused; dense index bounds are `nil` while holes exist; paged storage (1024 positions a page) |
| `StableUndirectedGraph<V>` | Undirected counterpart of `StableDirectedGraph` | The same pages and positions, one incidence row per vertex in position order (a self-loop twice); `SparselyIndexedGraph` |
| `FunctionalGraph` | Out-degree exactly 1 on `0..<n` | `cycleDecomposition()` in O(n) |

Data structures: `IndexedPriorityQueue` (4-ary min-heap over `0..<indexBound` with
decrease-key; not a `Sequence`), `RadixHeap` (monotone queue over `UInt` keys, no decrease-key),
`DisjointSet` (union by size, path halving), `LinkCutTree` (Sleator–Tarjan dynamic trees over
`0..<count`: link, cut, `makeRoot`, path minimum, addition and subtraction). Bit sets come from
swift-collections' `BitCollections`.
