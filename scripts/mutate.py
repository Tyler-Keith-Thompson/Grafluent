#!/usr/bin/env python3
"""Planted-bug (mutation) testing with mutant schemata.

Mutants are written by hand, one file per module in scripts/mutants/<Module>.py, as a list of
`Mutant(name, file, old, new, mode)`. Every mutant is compiled into one build of a scratch copy of
the package, each behind a runtime switch (Muter's "mutant schemata"), so the package is built
once rather than once per mutant:

    mode "expr":  old  ->  (__mutant(k) ? (new) : (old))   an expression
    mode "stmt":  old  ->  if __mutant(k) { new } else { old }   whole statements

`old` must occur once in the file, or `nth` picks the occurrence. `module` puts a mutant in another
module's file (Sources/<module>/<file>), for code the spec's module wires into; the spec's TESTS
then name the suites that reach it, run in order.
The environment variable GRAFLUENT_MUTANT picks the live mutant. Each mutant then runs the test
bundles named by the spec, several at once, and a run stops at its first failing test. A mutant is
caught when a test fails, the process crashes, or it runs past the time limit; it survived when
every test passes. A survivor needs a test or a note saying why it is equivalent.

Speed-reliant tests. A spec's bundle in PERFORMANCE_TESTS (scripts/modules.py) has a second
bundle, its Performance/ tests, which bound wall-clock time (`.timeLimit` on large inputs). Under
load from other work those bounds can fail on code no mutant changed, so the performance bundles
run only for the mutants every other test let through, one mutant at a time, and a failure there
counts only once it is confirmed: the failing tests run again unmutated, right away, and must
pass, and then fail again under the mutant. A confirmed kill is reported as "caught (timing)" when
a time limit decided it, or "caught (perf)" when a performance test's expectation failed. When the
unmutated run fails too, or the mutant's second run passes, the result is "INCONCLUSIVE": it is
not counted as caught and is not kept, so the next run tries that mutant again.

    python3 scripts/mutate.py ShortestPaths            # mutants whose inputs changed
    python3 scripts/mutate.py ShortestPaths rotate     # the named ones (if their inputs changed)
    python3 scripts/mutate.py ShortestPaths --all      # every mutant, ignoring stored results
    python3 scripts/mutate.py ShortestPaths --select   # coverage-based test selection
    python3 scripts/mutate.py ShortestPaths --jobs 2

Stored results. Each mutant's outcome is kept in results/<Module>.json under the mutation directory (see BASE) under a
key hashing everything it depends on: its definition and those of the mutants before it in the
same file (their text can move where its `old` matches), every source file of the test bundles'
modules and their dependencies (from scripts/modules.py), the bundles' own sources and
GrafluentTestSupport, Package.swift and Package.resolved, and the compiler version. A run only
builds and runs the mutants whose key changed; the rest are reported from the store, marked
"stored". The summary lists every mutant either way. `--all` ignores the store.

Timeouts. Several suites at once can push a slow survivor past the time limit, and a random
property test can take minutes on an unlucky input, so a mutant that times out runs once more
after the others, with less running; only a second timeout counts as caught.

Test selection (`--select`, off by default). One coverage pass runs every test of the unmutated
build in its own process, in a second copy (coverage/ under the mutation directory) where only the module under
test is compiled with -profile-generate, writing profiles continuously so that exit tests'
trapping children count too. llvm-cov maps each test to the lines it executed. A mutant then runs
first only the tests that execute a line of its schema (a test that never reaches the mutated
code behaves the same under the mutant, so it cannot catch it), or the full suite when no test
reaches it. A mutant that survives them then runs every other test too (Swift Testing's --skip),
so a survivor is always confirmed by the full suite and only kills get faster. The coverage pass
is stored like the results. On ColoringModule it found the same 109 caught and 13 survivors as the
full suite and was no faster: Swift Testing runs a suite in parallel and stops at the first
failure, so most kills take under a second either way, and survivors run everything regardless.
It may pay where kills come late, from slow tests.

The scratch copy lives in work/ under the mutation directory (~/Library/Caches/grafluent-mutation on macOS) and is kept between runs, so later builds are
incremental; files whose contents did not change keep their timestamps. The real sources are
never written.
"""

import argparse
import atexit
import dataclasses
import hashlib
import itertools
import json
import os
import re
import runpy
import shutil
import signal
import subprocess
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Outside the repository: root SwiftPM and Xcode builds manage .build/ and were seen to delete
# files from a scratch copy kept there mid-run. GRAFLUENT_MUTATION_DIR overrides the location.
BASE = os.environ.get("GRAFLUENT_MUTATION_DIR") or os.path.join(
    os.path.expanduser("~/Library/Caches") if sys.platform == "darwin" else os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")),
    "grafluent-mutation")
# One scratch copy per module, so runs on different modules proceed in parallel; runs on the same
# module take turns on that copy's lock. The module is the first positional argument.
_MODULE_ARG = next((a for a in sys.argv[1:] if not a.startswith("-")), "default")
WORK = os.path.join(BASE, "modules", _MODULE_ARG, "work")
RESULTS = os.path.join(BASE, "results")
# A second copy for the coverage pass, the same sources with the module instrumented, so the
# mutant runs use an uninstrumented build.
COVERAGE_WORK = os.path.join(BASE, "modules", _MODULE_ARG, "coverage")
SWIFT = ["env", "-u", "TOOLCHAINS", "xcrun", "--toolchain", "default", "swift"]
# Bump when the schemata, the runner or the stored format change meaning: every stored result
# is then stale.
STORE_VERSION = "3"

SWITCH = """\
// Generated by scripts/mutate.py in the mutation workspace only.
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

@usableFromInline let _activeMutant: Int = getenv("GRAFLUENT_MUTANT").map { Int(atoi($0)) } ?? -1

@usableFromInline @inline(never)
func __mutant(_ k: Int) -> Bool { _activeMutant == k }
"""

# Coverage for the module under test only, in COVERAGE_WORK: compiled with -profile-generate (the
# test bundles link the profile runtime).
INSTRUMENT = '.unsafeFlags(["-profile-generate", "-profile-coverage-mapping"])'
LINK_PROFILE = '.unsafeFlags(["-profile-generate"])'


@dataclasses.dataclass
class Mutant:
    name: str
    file: str
    old: str
    new: str
    mode: str = "expr"
    # Which occurrence of `old` to mutate when it occurs more than once (0 is the first).
    nth: int | None = None
    # The module whose Sources/<module>/<file> is mutated, when not the spec's own (a shared file
    # the spec's module wires into); the spec's TESTS must include a suite that reaches it.
    module: str | None = None


def load_spec(module):
    """The spec's mutants, its test bundles, and their speed-reliant bundles. A bundle's
    speed-reliant tests are a bundle of their own (PERFORMANCE_TESTS in scripts/modules.py), so a
    spec names only the first."""
    path = os.path.join(ROOT, "scripts", "mutants", f"{module}.py")
    spec = runpy.run_path(path, init_globals={"Mutant": Mutant})
    table = runpy.run_path(os.path.join(ROOT, "scripts", "modules.py"))
    timed = [table["performance_target"](b) for b in spec["TESTS"] if b in table["PERFORMANCE_TESTS"]]
    return spec["MUTANTS"], list(spec["TESTS"]), timed


# ── Stored results ───────────────────────────────────────────────────

def source_dirs(bundles):
    """Every directory whose sources the bundles are built from: the bundles, their modules and
    the modules' dependencies, transitively."""
    table = runpy.run_path(os.path.join(ROOT, "scripts", "modules.py"))
    deps = {name: d for name, _, _, d in table["MODULES"]}
    deps["GrafluentTestSupport"] = ["GraphProtocols"]
    tests = dict(table["TEST_TARGETS"])
    # A performance bundle's sources are in Performance/ under its module's test directory.
    home = {b: b for b in tests}
    for b in table["PERFORMANCE_TESTS"]:
        tests[table["performance_target"](b)] = tests[b]
        home[table["performance_target"](b)] = b
    dirs, seen = [], set()
    pending = []
    for b in bundles:
        if b not in tests:
            sys.exit(f"{b} is not a test target in scripts/modules.py")
        if os.path.join("Tests", home[b]) not in dirs:
            dirs.append(os.path.join("Tests", home[b]))
        pending += tests[b]
    while pending:
        d = pending.pop()
        if "/" in d or d in seen:  # an external product: Package.resolved pins it
            continue
        seen.add(d)
        dirs.append(os.path.join("Tests" if d == "GrafluentTestSupport" else "Sources", d))
        pending += deps[d]
    return sorted(dirs)


def pruned_manifest(bundles, modules=()):
    """Package.swift with only the bundles, the modules and everything they depend on. Other
    targets are left out of the workspace, so another module's unfinished edits cannot break this
    run's build, and their changes do not invalidate its stored results."""
    names = {os.path.basename(d) for d in source_dirs(bundles)} | set(modules) | set(bundles)
    with open(os.path.join(ROOT, "Package.swift")) as f:
        lines = f.read().split("\n")
    kept = [line for line in lines
            if not (m := re.match(r'\s*\.(?:library|target|testTarget)\(name: "([^"]+)"', line)) or m.group(1) in names]
    return "\n".join(kept)


def inputs_key(bundles):
    h = hashlib.sha256()
    h.update(STORE_VERSION.encode() + SWITCH.encode() + INSTRUMENT.encode())
    version = subprocess.run(SWIFT + ["--version"], capture_output=True, text=True).stdout
    h.update(version.encode())
    h.update(pruned_manifest(bundles).encode())
    files = ["Package.resolved"]
    for d in source_dirs(bundles):
        for parent, subdirs, names in os.walk(os.path.join(ROOT, d)):
            subdirs.sort()
            files += [os.path.relpath(os.path.join(parent, n), ROOT) for n in sorted(names)]
    for f in files:
        path = os.path.join(ROOT, f)
        h.update(b"\0" + f.encode() + b"\0")
        if os.path.exists(path):
            with open(path, "rb") as fh:
                h.update(hashlib.sha256(fh.read()).digest())
    return h.hexdigest()


def definition(m):
    fields = dataclasses.asdict(m)
    if fields["module"] is None:  # so specs without other modules keep their stored keys
        del fields["module"]
    return json.dumps(fields, sort_keys=True)


def mutant_keys(mutants, inputs):
    """Each mutant's key: the inputs, its definition and those of the earlier mutants on its
    file (whose replacements can move the text its `old` matches)."""
    keys = {}
    for k, m in enumerate(mutants):
        earlier = [definition(e) for e in mutants[:k + 1] if (e.module, e.file) == (m.module, m.file)]
        keys[m.name] = hashlib.sha256((inputs + "\0" + "\0".join(earlier)).encode()).hexdigest()
    return keys


def load_store(module):
    try:
        with open(os.path.join(RESULTS, f"{module}.json")) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_store(module, store):
    os.makedirs(RESULTS, exist_ok=True)
    path = os.path.join(RESULTS, f"{module}.json")
    with open(path + ".tmp", "w") as f:
        json.dump(store, f, indent=1, sort_keys=True)
    os.replace(path + ".tmp", path)


# ── The scratch workspace ────────────────────────────────────────────

def write_if_changed(path, data):
    """Writes only when the contents differ, so the build sees an unchanged file as unchanged."""
    data = data.encode() if isinstance(data, str) else data
    try:
        with open(path, "rb") as f:
            if f.read() == data:
                return
    except OSError:
        pass
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)


def sync_workspace(modules, bundles):
    """WORK: the bundles' directories and their modules' only (source_dirs), under a manifest
    naming just those (pruned_manifest)."""
    dirs = set(source_dirs(bundles)) | {os.path.join("Sources", m) for m in modules}
    for top in ["Sources", "Tests"]:
        os.makedirs(os.path.join(WORK, top), exist_ok=True)
        for name in os.listdir(os.path.join(WORK, top)):
            if os.path.join(top, name) not in dirs:
                path = os.path.join(WORK, top, name)
                shutil.rmtree(path) if os.path.isdir(path) else os.remove(path)
    # -c compares checksums so a file rewritten with the same contents keeps its mtime and does
    # not rebuild; --delete drops files gone from the checkout. The mutated modules get the
    # schemata (apply_schemata), written only where they changed.
    for d in sorted(dirs - {os.path.join("Sources", m) for m in modules}):
        subprocess.run(["rsync", "-a", "-c", "--delete", os.path.join(ROOT, d) + "/", os.path.join(WORK, d)], check=True)
    write_if_changed(os.path.join(WORK, "Package.swift"), pruned_manifest(bundles, modules).encode())


def sync_coverage_workspace(module, bundles):
    """COVERAGE_WORK: the schemata workspace's sources, with the module instrumented."""
    os.makedirs(COVERAGE_WORK, exist_ok=True)
    for item in ["Sources", "Tests"]:
        subprocess.run(["rsync", "-a", "-c", "--delete", os.path.join(WORK, item), COVERAGE_WORK], check=True)
    with open(os.path.join(WORK, "Package.swift")) as f:
        manifest = f.read()
    manifest, found = re.subn(rf'(\.target\(name: "{module}",.*?)\),\n',
                              rf'\1, swiftSettings: [{INSTRUMENT}]),\n', manifest, count=1)
    if not found:
        sys.exit(f"No target {module} in Package.swift")
    for b in bundles:
        manifest, found = re.subn(rf'(\.testTarget\(name: "{b}",.*?)\),\n',
                                  rf'\1, linkerSettings: [{LINK_PROFILE}]),\n', manifest, count=1)
        if not found:
            sys.exit(f"No test target {b} in Package.swift")
    write_if_changed(os.path.join(COVERAGE_WORK, "Package.swift"), manifest)


def mutated_modules(module, mutants):
    """The spec's module first, then every other module a mutant names."""
    return [module] + sorted({m.module for m in mutants if m.module and m.module != module})


def apply_schemata(module, mutants):
    """Writes each mutated module with every mutant behind its switch, and returns each mutant's
    span in the written files as {k: (file, first line, last line)}, 1-based; a file of another
    module than the spec's is named `<module>/<file>`, which coverage never reports."""
    spans = {}
    for mod in mutated_modules(module, mutants):
        own = [(k, m) for k, m in enumerate(mutants) if (m.module or module) == mod]
        for k, (file, first, last) in _apply_module(mod, own).items():
            spans[k] = (file if mod == module else f"{mod}/{file}", first, last)
    return spans


def _apply_module(module, numbered):
    source = os.path.join(ROOT, "Sources", module)
    target = os.path.join(WORK, "Sources", module)
    by_file = {}
    for k, m in numbered:
        by_file.setdefault(m.file, []).append((k, m))
    spans = {}
    written = {"_MutantSwitch.swift"}
    for parent, _, names in os.walk(source):
        for name in names:
            rel = os.path.relpath(os.path.join(parent, name), source)
            written.add(rel)
            if not name.endswith(".swift"):
                with open(os.path.join(source, rel), "rb") as f:
                    write_if_changed(os.path.join(target, rel), f.read())
                continue
            with open(os.path.join(source, rel)) as f:
                text = f.read()
            # Character spans of the replacements so far, moved and grown by later ones.
            chars = {}
            for k, m in by_file.pop(rel, []):
                count = text.count(m.old)
                if (m.nth is None and count != 1) or (m.nth is not None and m.nth >= count):
                    sys.exit(f"{m.name}: the old text occurs {count} times in {rel}")
                if m.mode == "expr":
                    replacement = f"(__mutant({k}) ? ({m.new}) : ({m.old}))"
                elif m.mode == "stmt":
                    indent = re.match(r"\s*", m.old).group(0)
                    replacement = f"{indent}if __mutant({k}) {{\n{m.new or indent + '()'}\n{indent}}} else {{\n{m.old}\n{indent}}}"
                else:
                    sys.exit(f"{m.name}: unknown mode {m.mode}")
                at = -1
                for _ in range((m.nth or 0) + 1):
                    at = text.index(m.old, at + 1)
                end = at + len(m.old)
                delta = len(replacement) - len(m.old)
                for j, (a, b) in chars.items():
                    if a >= end:
                        chars[j] = (a + delta, b + delta)
                    elif b >= end:
                        chars[j] = (a, b + delta)
                    elif b > at:
                        chars[j] = (a, at + len(replacement))
                chars[k] = (at, at + len(replacement))
                text = text[:at] + replacement + text[end:]
            for k, (a, b) in chars.items():
                spans[k] = (rel, text.count("\n", 0, a) + 1, text.count("\n", 0, max(a, b - 1)) + 1)
            write_if_changed(os.path.join(target, rel), text)
    if by_file:
        sys.exit(f"No such files in Sources/{module}: {', '.join(sorted(by_file))}")
    write_if_changed(os.path.join(target, "_MutantSwitch.swift"), SWITCH)
    for parent, _, names in os.walk(target):
        for name in names:
            if os.path.relpath(os.path.join(parent, name), target) not in written:
                os.remove(os.path.join(parent, name))
    return spans


def build(workspace=WORK):
    """Seconds taken, or the build's errors as a string."""
    started = time.time()
    result = subprocess.run(SWIFT + ["build", "--build-tests"], cwd=workspace, capture_output=True, text=True, timeout=3600)
    if result.returncode != 0:
        errors = [line for line in result.stdout.splitlines() + result.stderr.splitlines() if "error:" in line]
        return "\n".join(errors[:40] or result.stderr.splitlines()[-40:])
    return time.time() - started


def test_command(bundle, workspace=WORK):
    developer = subprocess.run(["xcode-select", "-p"], capture_output=True, text=True).stdout.strip()
    swift = subprocess.run(["env", "-u", "TOOLCHAINS", "xcrun", "--toolchain", "default", "-f", "swift"],
                           capture_output=True, text=True).stdout.strip()
    helper = os.path.join(os.path.dirname(swift), "..", "libexec", "swift", "pm", "swiftpm-testing-helper")
    binary = os.path.join(workspace, ".build", "debug", f"{bundle}.xctest", "Contents", "MacOS", bundle)
    env = dict(os.environ)
    env["DYLD_FRAMEWORK_PATH"] = os.path.join(developer, "Platforms/MacOSX.platform/Developer/Library/Frameworks")
    env["DYLD_LIBRARY_PATH"] = os.path.join(developer, "Platforms/MacOSX.platform/Developer/usr/lib")
    env["NO_COLOR"] = "1"
    # Mutant runs write no profile; the coverage pass sets its own.
    env["LLVM_PROFILE_FILE"] = "/dev/null"
    return [helper, "--test-bundle-path", binary, "--testing-library", "swift-testing"], env


# ── Running tests ────────────────────────────────────────────────────

FAILURE = re.compile(r"✘ Test (.*?) (?:recorded an issue|failed)(.*)")
# How Swift Testing reports a `.timeLimit` it ran past.
TIME_LIMIT = "Time limit was exceeded"
RUNS = itertools.count()


def reap(run=None):
    """Kills test processes left over from the mutation workspace: those of one run (by the
    GRAFLUENT_MUTATION_RUN they inherited), or all of them. Exit tests run in child processes
    outside the runner's process group, and a mutant that removes a precondition can leave one
    running forever; killing the group alone left a hundred of them behind."""
    listing = subprocess.run(["ps", "-A", "-E", "-ww", "-o", "pid=,command="], capture_output=True, text=True).stdout
    marker = f"GRAFLUENT_MUTATION_RUN={run} " if run is not None else None
    for line in listing.splitlines():
        if WORK not in line or (marker and marker not in line + " "):
            continue
        pid = int(line.split(None, 1)[0])
        if pid == os.getpid():
            continue
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass


def run_bundle(command, env, mutant, limit, extra=(), stream=None):
    """Returns (outcome, detail): outcome is "passed", "failed", "crashed" or "timed out". With
    `stream`, Swift Testing also writes its JSON event stream there (see failing_tests)."""
    run = next(RUNS)
    env = dict(env, GRAFLUENT_MUTANT=str(mutant), GRAFLUENT_MUTATION_RUN=str(run))
    if stream:
        extra = list(extra) + ["--event-stream-output-path", stream, "--event-stream-version", "0"]
    process = subprocess.Popen(command + list(extra), env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, errors="replace", start_new_session=True)
    def kill():
        # The group may already be gone, or be exiting (macOS then answers EPERM).
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except (ProcessLookupError, PermissionError):
            pass

    timer = threading.Timer(limit, kill)
    timer.start()
    failure = None
    tail = []
    try:
        for line in process.stdout:
            tail = (tail + [line.rstrip()])[-5:]
            match = FAILURE.search(line)
            if match:
                failure = match.group(1)
                if TIME_LIMIT in match.group(2):
                    failure += f" ({TIME_LIMIT.lower()})"
                kill()
                break
        process.wait()
    finally:
        timed_out = not timer.is_alive() and failure is None and process.returncode == -signal.SIGKILL
        timer.cancel()
        reap(run)
    if failure:
        return "failed", failure
    if timed_out:
        return "timed out", f"after {limit:.0f} s" + (f"; last output: {tail[-1][:200]}" if tail else "")
    if process.returncode != 0:
        return "crashed", f"exit {process.returncode}: {tail[-1] if tail else ''}"
    return "passed", ""


def exactly(test_id):
    """A Swift Testing --filter / --skip pattern for one test (IDs may carry a source location
    after a further slash)."""
    return "^" + re.escape(test_id) + "(/|$)"


def failing_tests(stream):
    """The IDs of the test functions a run's event stream blames: those that recorded an issue,
    or, when none did (a crash, or the runner's own time limit), those that started and never
    ended. Empty when the stream names neither; the run may have been killed mid-line, so a line
    that does not parse is skipped."""
    functions, issues, started, ended = set(), [], [], set()
    try:
        with open(stream, errors="replace") as f:
            lines = f.read().splitlines()
    except OSError:
        return []
    for line in lines:
        try:
            record = json.loads(line)
        except ValueError:
            continue
        payload = record.get("payload", {})
        if record.get("kind") == "test" and payload.get("kind") == "function":
            functions.add(payload.get("id"))
        elif record.get("kind") == "event":
            test = payload.get("testID")
            if payload.get("kind") == "issueRecorded":
                issues.append(test)
            elif payload.get("kind") == "testStarted":
                started.append(test)
            elif payload.get("kind") == "testEnded":
                ended.add(test)
    blamed = issues or [t for t in started if t not in ended]
    return sorted({t for t in blamed if t in functions})


def list_tests(command, env, bundle):
    out = subprocess.run(command + ["--list-tests"], env=env, capture_output=True, text=True, timeout=600)
    if out.returncode != 0:
        sys.exit(f"Could not list the tests of {bundle}:\n{out.stdout[-2000:]}{out.stderr[-2000:]}")
    return [line.strip() for line in out.stdout.splitlines() if line.startswith(bundle + ".")]


def coverage(module, bundles, jobs, limit):
    """{bundle: [test IDs]}, and {(file, line): {(bundle, test index)}} for the module's files,
    from one process per test of the unmutated, instrumented build in COVERAGE_WORK. None when a
    test fails on its own (the suite then depends on test order, and selection would not be
    sound)."""
    commands = [test_command(b, COVERAGE_WORK) for b in bundles]
    profiles = os.path.join(COVERAGE_WORK, "profiles")
    shutil.rmtree(profiles, ignore_errors=True)
    os.makedirs(profiles)
    tests = {b: list_tests(command, env, b) for (command, env), b in zip(commands, bundles)}
    work = [(b, i, command, env) for (command, env), b in zip(commands, bundles) for i in range(len(tests[b]))]
    failed = []

    def run(item):
        b, i, command, env = item
        # %c: continuous mode, so a child that traps (an exit test) still leaves its counts.
        env = dict(env, LLVM_PROFILE_FILE=os.path.join(profiles, f"{b}-{i}-%p%c.profraw"))
        outcome, detail = run_bundle(command, env, -1, limit, ["--filter", exactly(tests[b][i])])
        if outcome != "passed":
            failed.append(f"{tests[b][i]}: {outcome} {detail}")

    with ThreadPoolExecutor(max_workers=jobs) as pool:
        list(pool.map(run, work))
    if failed:
        print("Selection is off: these tests fail when run alone:\n  " + "\n  ".join(failed[:10]), flush=True)
        return None
    objects = os.path.join(COVERAGE_WORK, ".build", "debug", f"{module}.o")
    if not os.path.exists(objects):
        objects = commands[0][0][commands[0][0].index("--test-bundle-path") + 1]
    prefix = os.path.join(COVERAGE_WORK, "Sources", module) + os.sep
    lines = {}
    by_test = {}
    for name in os.listdir(profiles):
        b, i, _ = name.rsplit("-", 2)
        by_test.setdefault((b, int(i)), []).append(os.path.join(profiles, name))
    if len(by_test) != len(work):
        print(f"Selection is off: {len(work) - len(by_test)} tests left no profile", flush=True)
        return None

    def export(item):
        (b, i), raws = item
        data = os.path.join(profiles, f"{b}-{i}.profdata")
        subprocess.run(["xcrun", "llvm-profdata", "merge", "-sparse", *raws, "-o", data], check=True, timeout=600)
        lcov = subprocess.run(["xcrun", "llvm-cov", "export", "-format=lcov", "-instr-profile", data, objects],
                              capture_output=True, text=True, check=True, timeout=600).stdout
        hit = []
        file = None
        for line in lcov.splitlines():
            if line.startswith("SF:"):
                file = line[3:][len(prefix):] if line[3:].startswith(prefix) else None
            elif line.startswith("DA:") and file:
                number, count = line[3:].split(",")[:2]
                if int(count) > 0:
                    hit.append((file, int(number)))
        return (b, i), hit

    with ThreadPoolExecutor(max_workers=jobs) as pool:
        for test, hit in pool.map(export, by_test.items()):
            for at in hit:
                lines.setdefault(at, set()).add(test)
    shutil.rmtree(profiles, ignore_errors=True)
    return tests, lines


def load_coverage(module, key):
    try:
        with open(os.path.join(RESULTS, f"{module}.coverage.json")) as f:
            stored = json.load(f)
    except (OSError, ValueError):
        return None
    if stored.get("key") != key:
        return None
    lines = {(file, line): {(b, i) for b, i in hit} for file, line, hit in stored["lines"]}
    return stored["tests"], lines


def save_coverage(module, key, selection):
    tests, lines = selection
    os.makedirs(RESULTS, exist_ok=True)
    with open(os.path.join(RESULTS, f"{module}.coverage.json"), "w") as f:
        json.dump({"key": key, "tests": tests,
                   "lines": [[file, line, sorted(hit)] for (file, line), hit in sorted(lines.items())]}, f)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("module")
    parser.add_argument("names", nargs="*", help="run only these mutants")
    parser.add_argument("--jobs", type=int, default=max(1, (os.cpu_count() or 4) // 5))
    parser.add_argument("--all", action="store_true", help="run every chosen mutant, ignoring stored results")
    parser.add_argument("--select", action="store_true",
                        help="run each mutant first against only the tests that reach it (coverage-based)")
    args = parser.parse_args()

    # One run per module at a time: a second run on the same module would overwrite the first's
    # sources and builds in WORK. Later runs on that module wait here for the lock.
    import fcntl
    os.makedirs(os.path.dirname(WORK), exist_ok=True)
    # Kept in a name of its own for the whole run: rebinding it would close the file and drop the lock.
    workspace_lock = open(WORK + ".lock", "w")
    try:
        fcntl.flock(workspace_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        print("Another mutation run holds the workspace; waiting for it to finish...", flush=True)
        fcntl.flock(workspace_lock, fcntl.LOCK_EX)

    mutants, bundles, timed = load_spec(args.module)
    names = {m.name for m in mutants}
    if len(names) != len(mutants):
        sys.exit("Mutant names must be unique")
    unknown = set(args.names) - names
    if unknown:
        sys.exit(f"No such mutants: {', '.join(sorted(unknown))}")

    inputs = inputs_key(bundles + timed)
    keys = mutant_keys(mutants, inputs)
    store = load_store(args.module)
    chosen = [(k, m) for k, m in enumerate(mutants) if not args.names or m.name in args.names]
    stale = [(k, m) for k, m in chosen if args.all or store.get(m.name, {}).get("key") != keys[m.name]]
    print(f"{len(chosen) - len(stale)} of {len(chosen)} mutants stored with unchanged inputs; {len(stale)} to run", flush=True)
    lock = threading.Lock()
    started = time.time()
    width = max(len(m.name) for _, m in chosen)

    def record(m, status, detail, tests, seconds, by=None):
        """Stores and prints one mutant's result. An inconclusive one is stored without its key, so
        the next run tries it again."""
        with lock:
            store[m.name] = {"key": keys[m.name] if status != "inconclusive" else None, "status": status,
                             "detail": detail, "tests": tests, "seconds": round(seconds, 1)}
            if by:
                store[m.name]["by"] = by
            save_store(args.module, store)
            print(f"{m.name:<{width}}  {label(store[m.name])} {seconds:5.1f} s  {detail}  [{tests}]", flush=True)

    if stale:
        atexit.register(reap)
        sync_workspace(mutated_modules(args.module, mutants), bundles + timed)
        spans = apply_schemata(args.module, mutants)
        # The coverage build, when selection needs a new pass, goes alongside the schemata build.
        coverage_key = hashlib.sha256((inputs + "\0" + "\0".join(map(definition, mutants))).encode()).hexdigest()
        selection = None if not args.select else load_coverage(args.module, coverage_key)
        coverage_build = []
        if args.select and selection is None:
            # Every bundle links the instrumented module, so every one links the profile runtime.
            sync_coverage_workspace(args.module, bundles + timed)
            builder = threading.Thread(target=lambda: coverage_build.append(build(COVERAGE_WORK)), daemon=True)
            builder.start()
        took = build()
        if isinstance(took, str):
            sys.exit("The schemata build failed:\n" + took)
        print(f"Built {len(mutants)} mutants into one build in {took:.0f} s", flush=True)

        commands = [test_command(b) for b in bundles]
        baseline = 0
        for (command, env), bundle in zip(commands, bundles):
            began = time.time()
            outcome, detail = run_bundle(command, env, -1, 600)
            if outcome == "timed out":
                # As for mutants below: a timeout counts when it happens twice.
                print(f"{bundle} timed out without a mutant ({detail}); running it again", flush=True)
                began = time.time()
                outcome, detail = run_bundle(command, env, -1, 600)
            if outcome != "passed":
                sys.exit(f"{bundle} does not pass without a mutant ({outcome}: {detail})")
            baseline += time.time() - began
        # Running several bundles at once slows each one, so the limit is generous.
        limit = 3 * baseline + 30
        print(f"Unmutated tests pass in {baseline:.0f} s; each mutant gets {limit:.0f} s", flush=True)

        if args.select and selection is None:
            builder.join()
            if isinstance(coverage_build[0], str):
                sys.exit("The coverage build failed:\n" + coverage_build[0])
            covered = time.time()
            selection = coverage(args.module, bundles, max(1, os.cpu_count() or 4), limit)
            if selection:
                save_coverage(args.module, coverage_key, selection)
                total = sum(len(t) for t in selection[0].values())
                print(f"Coverage of {total} tests, one process each, built alongside and run in "
                      f"{time.time() - covered:.0f} s", flush=True)
        elif selection is not None:
            print("Coverage stored with unchanged inputs", flush=True)

        def selected(k):
            """{bundle: [test IDs]} reaching mutant k, or None for the full suite."""
            if selection is None:
                return None
            tests, lines = selection
            file, first, last = spans[k]
            reached = set().union(*(lines.get((file, n), set()) for n in range(first, last + 1)))
            if not reached:
                return None
            return {b: [tests[b][i] for i in sorted(i for c, i in reached if c == b)] for b in bundles}

        retry = []
        # Mutants every test outside the performance bundles let through: (k, m, seconds, tests).
        through = []

        def run(item, again=False):
            k, m = item
            began = time.time()
            chosen_tests = selected(k)
            phases = [("all", None)] if chosen_tests is None else [("selected", True), ("rest", False)]
            result = None
            ran = 0
            for phase, only in phases:
                for (command, env), bundle in zip(commands, bundles):
                    if only is None:
                        extra = []
                    else:
                        ids = chosen_tests[bundle]
                        everything = len(ids) == len(selection[0][bundle])
                        if only and not ids or not only and everything:
                            continue
                        flag = "--filter" if only else "--skip"
                        extra = [a for t in ids for a in (flag, exactly(t))]
                    outcome, detail = run_bundle(command, env, k, limit, extra)
                    if outcome == "timed out" and not again:
                        # Several suites at once can push a slow survivor past the limit; a
                        # timeout only counts when it happens again with less running.
                        with lock:
                            retry.append(item)
                            print(f"{m.name:<{width}}  timed out after {limit:.0f} s; it runs again at the end", flush=True)
                        return
                    if outcome != "passed":
                        result = ("caught", f"{bundle}: {outcome} {detail}")
                        break
                if result:
                    break
                ran += 1
            if chosen_tests is None:
                tests = "every test"
            else:
                count = sum(len(v) for v in chosen_tests.values())
                tests = f"{count} selected tests" + (", then the rest" if ran or result is None else "")
            seconds = time.time() - began
            if result is None and timed:
                with lock:
                    through.append((k, m, seconds, tests))
                return
            record(m, *(result or ("survived", "")), tests, seconds)

        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            list(pool.map(run, stale))
        if retry:
            with ThreadPoolExecutor(max_workers=args.jobs) as pool:
                list(pool.map(lambda item: run(item, again=True), retry))
        if through:
            run_timed(timed, sorted(through, key=lambda t: t[0]), record)

    # Every chosen mutant, in spec order, whether it ran now or was stored.
    ran_now = {m.name for _, m in stale}
    survivors, unsure, by_timing = [], [], 0
    print(f"\n{'mutant':<{width}}  status           source  detail")
    for _, m in chosen:
        entry = store[m.name]
        if entry["status"] == "survived":
            survivors.append(m.name)
        elif entry["status"] == "inconclusive":
            unsure.append(m.name)
        elif entry.get("by"):
            by_timing += 1
        print(f"{m.name:<{width}}  {label(entry):<15}  {'ran   ' if m.name in ran_now else 'stored'}  {entry['detail']}")
    caught = len(chosen) - len(survivors) - len(unsure)
    print(f"{caught} of {len(chosen)} caught"
          + (f" ({by_timing} only by performance tests, confirmed)" if by_timing else "")
          + f" ({len(chosen) - len(stale)} stored, {len(stale)} run) in {time.time() - started:.0f} s"
          + (f"; survived: {', '.join(survivors)}" if survivors else "")
          + (f"; inconclusive, run again: {', '.join(unsure)}" if unsure else ""))


def label(entry):
    """A stored result's status as the report shows it."""
    if entry["status"] == "caught":
        return {"timing": "caught (timing)", "performance": "caught (perf)"}.get(entry.get("by"), "caught")
    return entry["status"].upper()


def run_timed(timed, through, record):
    """The performance bundles (`timed`), for the mutants every other test let through, one
    mutant at a time so this run adds no load of its own to their time limits. A failure counts
    only when the failing tests then pass unmutated and fail under the mutant again."""
    commands = [test_command(b) for b in timed]
    # Their own baseline, with a second chance: load from other work can fail a time limit.
    baseline = 0
    for (command, env), bundle in zip(commands, timed):
        for attempt in range(2):
            began = time.time()
            outcome, detail = run_bundle(command, env, -1, 600)
            if outcome == "passed":
                baseline += time.time() - began
                break
            print(f"{bundle} {outcome} without a mutant ({detail})"
                  + ("; running it again" if attempt == 0 else ""), flush=True)
        else:
            for k, m, seconds, tests in through:
                record(m, "inconclusive", f"{bundle} fails without a mutant ({outcome}: {detail})", tests, seconds)
            return
    limit = 3 * baseline + 30
    print(f"{len(through)} mutants passed every other test; the performance tests "
          f"({', '.join(timed)}) pass unmutated in {baseline:.0f} s, and each mutant gets {limit:.0f} s", flush=True)
    stream = os.path.join(os.path.dirname(WORK), "events.jsonl")

    for k, m, seconds, tests in through:
        began = time.time()
        result = ("survived", "", None)
        for (command, env), bundle in zip(commands, timed):
            if os.path.exists(stream):
                os.remove(stream)
            outcome, detail = run_bundle(command, env, k, limit, stream=stream)
            if outcome == "passed":
                continue
            # Confirm: the blamed tests (the whole bundle when the stream names none) pass
            # unmutated, right away, and fail under the mutant again.
            blamed = failing_tests(stream)
            extra = [a for t in blamed for a in ("--filter", exactly(t))]
            which = f"{len(blamed)} test{'s' * (len(blamed) != 1)}" if blamed else "the whole bundle"
            first = f"{bundle}: {outcome} {detail}"
            base, base_detail = run_bundle(command, env, -1, limit, extra)
            if base != "passed":
                result = ("inconclusive", f"{first}; unmutated, {which} {base} too ({base_detail})", None)
                continue
            again, again_detail = run_bundle(command, env, k, limit, extra)
            if again == "passed":
                result = ("inconclusive", f"{first}; unmutated, {which} passed; under the mutant again, passed", None)
                continue
            timing = outcome == "timed out" or again == "timed out" or TIME_LIMIT.lower() in detail + again_detail
            result = ("caught", f"{first}; confirmed on {which}: unmutated passed, then {again} again",
                      "timing" if timing else "performance")
            break
        status, detail, by = result
        record(m, status, detail, tests + ", then the performance tests", seconds + time.time() - began, by)


if __name__ == "__main__":
    main()
