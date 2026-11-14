PROJECT_ROOT := justfile_directory()
BAZEL := "bazel"

# Optimized builds use a separate output base: switching --compilation_mode changes the
# configuration, and sharing a base with debug builds would discard the analysis cache on every
# switch (which .bazelrc refuses).
BAZEL_RELEASE := "bazel --output_base=" + home_directory() + "/Library/Caches/bazel-grafluent-release"

# SwiftPM runs through Xcode's default toolchain. A development snapshot selected through
# TOOLCHAINS (or first on PATH via swiftly) can fail to read the SDK's Testing module.
SWIFT := "env -u TOOLCHAINS xcrun --toolchain default swift"
# The checkout of BenchmarkHarness whose benchmark-harness tool records simulated baselines.
BENCHMARK_HARNESS := env("BENCHMARK_HARNESS", home_directory() / "workspace" / "BenchmarkHarness")

[doc('Build everything (default)')]
all: build

[doc('Build every target')]
build:
    {{BAZEL}} build //...

[doc('Run every test')]
test:
    {{BAZEL}} test //...

[doc('Run one test target, e.g. just test-one //Tests/GrafluentRepresentationsTests')]
test-one target:
    {{BAZEL}} test {{target}}

[doc('Run tests matching a filter, e.g. just filter AdjacencyList')]
filter pattern:
    {{BAZEL}} test //... --test_filter={{pattern}}

[doc('Run the speed-reliant tests (the PerformanceTests targets) optimized (-O); the rest run in debug only')]
test-release:
    {{BAZEL_RELEASE}} test --config=release //...

[doc('Re-resolve SwiftPM dependencies for Bazel after editing the package table')]
resolve:
    cd {{PROJECT_ROOT}}/swift && {{SWIFT}} package resolve

[doc('Build via SwiftPM too, to verify the published package')]
spm:
    {{SWIFT}} build

[doc('Run the tests via SwiftPM')]
spm-test *args="":
    {{SWIFT}} test {{args}}

[doc('Verify both build systems agree — run before pushing')]
verify: test spm-test

[doc('Regenerate Package.swift and every BUILD.bazel from scripts/modules.py')]
modules:
    python3 scripts/modules.py

[doc('Plant the bugs in scripts/mutants/<module>.py and report survivors; only mutants whose code or tests changed run (--all: every one; --select: coverage-based test selection). Performance tests run only for survivors of the rest, and their kills count once confirmed against an unmutated run, e.g. just mutate ShortestPaths')]
mutate module *args="":
    python3 {{PROJECT_ROOT}}/scripts/mutate.py {{module}} {{args}}

[doc('Build the combined DocC site for every library module into .build/docs (what the DocC workflow publishes)')]
docs:
    {{BAZEL}} build //:docs
    rm -rf {{PROJECT_ROOT}}/.build/docs && mkdir -p {{PROJECT_ROOT}}/.build
    cp -RL {{PROJECT_ROOT}}/bazel-bin/docs {{PROJECT_ROOT}}/.build/docs && chmod -R u+w {{PROJECT_ROOT}}/.build/docs

[doc('Build the browser explorer (Explore/) as size-optimized release WebAssembly into Explore/dist')]
explore:
    {{PROJECT_ROOT}}/Explore/build.sh

[doc('SwiftPM tests on wasm32-wasi under wasmtime, a 32-bit Int, in groups of targets, e.g. just wasi-test, just wasi-test -c release, or just wasi-test --targets SemiringsTests')]
wasi-test *args="":
    python3 -u {{PROJECT_ROOT}}/scripts/wasi_test.py {{args}}

[doc('Fuzz with libFuzzer, time-boxed, e.g. just fuzz, or just fuzz FuzzShortestPaths -t 600')]
fuzz *args="":
    python3 {{PROJECT_ROOT}}/scripts/fuzz.py run {{args}}

[doc('Replay every fuzz corpus once, after a change')]
fuzz-regress *args="":
    python3 {{PROJECT_ROOT}}/scripts/fuzz.py regress {{args}}

[doc('Replay and minimize one crash, e.g. just fuzz-repro FuzzShortestPaths Fuzz/Crashes/FuzzShortestPaths/crash-…')]
fuzz-repro target input:
    python3 {{PROJECT_ROOT}}/scripts/fuzz.py repro {{target}} {{input}}

[doc('Differential testing against NetworkX, scipy, rustworkx and igraph, built through Bazel (-O); --module X (repeatable) compares one module only, e.g. just diff, just diff --module Coloring, or just diff --cases 20000 --seed 7')]
diff *args="":
    python3 {{PROJECT_ROOT}}/scripts/differential.py {{args}}

[doc('Run the benchmarks, e.g. just bench, or just bench --target CompressedSparseRowBenchmarks')]
bench *args="":
    cd {{PROJECT_ROOT}}/Benchmarks && {{SWIFT}} package --allow-writing-to-package-directory benchmark {{args}}

[doc('Record the current results as the baseline named main')]
bench-baseline:
    cd {{PROJECT_ROOT}}/Benchmarks && {{SWIFT}} package --allow-writing-to-package-directory benchmark baseline update main

[doc('Compare the current results against the saved baseline')]
bench-compare:
    cd {{PROJECT_ROOT}}/Benchmarks && {{SWIFT}} package --allow-writing-to-package-directory benchmark baseline compare main

[doc("Record the benchmarks' simulated counts (Callgrind in a Linux VM; steady on a busy machine) as the simulated baseline, measuring only targets whose code changed (Bazel caches the rest), e.g. just bench-simulated, or just bench-simulated --target X")]
bench-simulated *args="": (_simulated-baseline "simulated" args)

[doc("Record simulated counts as simulated-current and compare them against the simulated baseline, e.g. just bench-simulated-compare --target X")]
bench-simulated-compare *args="": (_simulated-baseline "simulated-current" "--fresh " + args)
    cd {{PROJECT_ROOT}}/Benchmarks && {{SWIFT}} package --allow-writing-to-package-directory benchmark baseline compare simulated simulated-current {{args}}

[private]
_simulated-baseline name args:
    BENCHMARK_HARNESS={{BENCHMARK_HARNESS}} python3 {{PROJECT_ROOT}}/scripts/bench_simulated.py {{name}} {{args}}

[doc('Generate an Xcode project from the Bazel graph and open it')]
generate *args="":
    @bash scripts/generate-xcodeproj.sh {{args}}

[doc('Build optimized: the library and the speed-reliant tests, not the debug-only test targets')]
release:
    {{BAZEL_RELEASE}} build --config=release //...

[doc('Store the BuildBuddy API key in the login Keychain (asks for it), once per Mac: every project from the template then builds with the remote cache (tools/bazel)')]
buildbuddy-key:
    #!/usr/bin/env bash
    set -euo pipefail
    read -r -s -p "BuildBuddy API key (hidden): " key
    echo
    if [ -z "$key" ]; then
        echo "No key entered; nothing stored" >&2
        exit 1
    fi
    # Through security's own command reader, so the key never appears in a process's arguments.
    printf 'add-generic-password -U -s buildbuddy -a api-key -l "BuildBuddy API key" -w %s\n' "$key" | security -i >/dev/null
    echo "Stored. Builds use BuildBuddy from the next Bazel command."

[doc('Set this repository’s BUILDBUDDY_API_KEY Actions secret from the Keychain with gh, so CI uses the remote cache too')]
ci-secrets:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! key="$(security find-generic-password -s buildbuddy -a api-key -w 2>/dev/null)"; then
        echo "No BuildBuddy API key in the Keychain; store it with just buildbuddy-key" >&2
        exit 1
    fi
    printf '%s' "$key" | gh secret set BUILDBUDDY_API_KEY

[doc('Remove all build artifacts')]
clean:
    {{BAZEL}} clean
    {{BAZEL_RELEASE}} clean || true
    rm -rf {{PROJECT_ROOT}}/.build

[doc('Print the dependency graph of a target')]
deps target="//Sources/Grafluent":
    {{BAZEL}} query 'deps({{target}})' --output=label_kind

[doc('List every buildable target')]
targets:
    {{BAZEL}} query '//...' --output=label_kind

[doc('Compare Grafluent with petgraph, rustworkx-core, BGL, LEMON, igraph and PCSR on identical instances (Benchmarks/CrossLanguage/README.md), e.g. just bench-cross, or just bench-cross --scale smoke --repeat 3')]
bench-cross *args="":
    python3 {{PROJECT_ROOT}}/Benchmarks/CrossLanguage/run.py {{args}}

# The checkout of ProjectTemplate this project came from; .template.json records the commit.
PROJECT_TEMPLATE := env("PROJECT_TEMPLATE", home_directory() / "workspace" / "ProjectTemplate")

[doc('Merge the project template’s changes since .template.json’s commit into this checkout (needs a clean worktree), e.g. just template-update, or just template-update --to <commit>')]
template-update *args="":
    python3 {{PROJECT_TEMPLATE}}/template.py update {{PROJECT_ROOT}} {{args}}
