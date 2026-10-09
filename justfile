PROJECT_ROOT := justfile_directory()
BAZEL := "bazel"

# Optimized builds use a separate output base: switching --compilation_mode changes the
# configuration, and sharing a base with debug builds would discard the analysis cache on every
# switch (which .bazelrc refuses).
BAZEL_RELEASE := "bazel --output_base=" + home_directory() + "/Library/Caches/bazel-grafluent-release"

# SwiftPM runs through Xcode's default toolchain. A development snapshot selected through
# TOOLCHAINS (or first on PATH via swiftly) can fail to read the SDK's Testing module.
SWIFT := "env -u TOOLCHAINS xcrun --toolchain default swift"

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

[doc('Run every test optimized (-O), where copy-on-write and inlining bugs tend to surface')]
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

[doc('Plant the bugs in scripts/mutants/<module>.py and report survivors, e.g. just mutate ShortestPaths')]
mutate module *args="":
    python3 {{PROJECT_ROOT}}/scripts/mutate.py {{module}} {{args}}

[doc('Fuzz with libFuzzer, time-boxed, e.g. just fuzz, or just fuzz FuzzShortestPaths -t 600')]
fuzz *args="":
    python3 {{PROJECT_ROOT}}/scripts/fuzz.py run {{args}}

[doc('Replay every fuzz corpus once, after a change')]
fuzz-regress *args="":
    python3 {{PROJECT_ROOT}}/scripts/fuzz.py regress {{args}}

[doc('Replay and minimize one crash, e.g. just fuzz-repro FuzzShortestPaths Fuzz/Crashes/FuzzShortestPaths/crash-…')]
fuzz-repro target input:
    python3 {{PROJECT_ROOT}}/scripts/fuzz.py repro {{target}} {{input}}

[doc('Differential testing against NetworkX and scipy, e.g. just diff, or just diff --cases 20000 --seed 7')]
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

[doc('Generate an Xcode project from the Bazel graph and open it')]
generate *args="":
    @bash scripts/generate-xcodeproj.sh {{args}}

[doc('Build optimized')]
release:
    {{BAZEL_RELEASE}} build --config=release //...

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
