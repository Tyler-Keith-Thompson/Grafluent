#!/usr/bin/env python3
"""Coverage-guided fuzzing with libFuzzer, time-boxed.

The targets live in Fuzz/ (one per component, each checking against a simple model). Xcode's
toolchain has no libFuzzer runtime, so they are built with a swift.org toolchain through swiftly
(GRAFLUENT_FUZZ_SWIFT, default 6.3.3; `swiftly install 6.3.3` once).

    python3 scripts/fuzz.py run                         # every target, 60 s each, all at once
    python3 scripts/fuzz.py run FuzzShortestPaths -t 600
    python3 scripts/fuzz.py regress                     # replay every committed corpus once
    python3 scripts/fuzz.py repro FuzzShortestPaths Fuzz/Crashes/FuzzShortestPaths/crash-…

A run is bounded by time, not by inputs: each target gets `--seconds` of wall time on
`--jobs` worker processes (libFuzzer's fork mode), with every target running at once. New inputs
are written to a scratch directory and then merged into Fuzz/Corpus/<target>/, keeping only the
ones that add coverage, so every run starts where the last one stopped. The corpus is local (a
few hundred inputs per target, not committed); `regress` replays it after a change. Crashes go to Fuzz/Crashes/<target>/ (not committed); a crash becomes a test in the
module's suite, and then its file is deleted. `repro` replays one and also writes a minimized
copy next to it.
"""

import argparse
import glob
import os
import shutil
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FUZZ = os.path.join(ROOT, "Fuzz")
BIN = os.path.join(FUZZ, ".build", "release")
VERSION = os.environ.get("GRAFLUENT_FUZZ_SWIFT", "6.3.3")

# Common to every libFuzzer invocation. Inputs decode into operation sequences, so a few hundred
# bytes is already a long sequence; longer inputs only slow each run. The memory limit follows
# the experience that the 2 GB default stops long runs early.
COMMON = ["-max_len=512", "-rss_limit_mb=4096", "-timeout=10", "-use_value_profile=1", "-print_final_stats=1"]


def targets():
    return sorted(os.path.basename(p) for p in glob.glob(os.path.join(FUZZ, "Sources", "Fuzz*")) if not p.endswith("FuzzSupport"))


def build():
    swiftly = shutil.which("swiftly") or os.path.expanduser("~/.swiftly/bin/swiftly")
    # Resolve first: a package added to the library is otherwise missing from this package's
    # stale resolution ("no such module").
    subprocess.run([swiftly, "run", "swift", "package", "resolve", f"+{VERSION}"], cwd=FUZZ, capture_output=True)
    command = [swiftly, "run", "swift", "build", "-c", "release", "-Xswiftc", "-sanitize=fuzzer,address", f"+{VERSION}"]
    result = subprocess.run(command, cwd=FUZZ, capture_output=True, text=True)
    # The swift.org toolchain reads the newer SDK's interfaces with an argument it does not know
    # and falls back; the message is noise.
    lines = [l for l in (result.stdout + result.stderr).splitlines() if "-target-arch-variant" not in l]
    if result.returncode != 0:
        sys.exit("The fuzz build failed:\n" + "\n".join(l for l in lines if "error" in l or "warning" in l)[-4000:])


def run(target, seconds, jobs):
    corpus = os.path.join(FUZZ, "Corpus", target)
    crashes = os.path.join(FUZZ, "Crashes", target)
    os.makedirs(corpus, exist_ok=True)
    os.makedirs(crashes, exist_ok=True)
    before = set(os.listdir(crashes))
    scratch = tempfile.mkdtemp(prefix=f"{target}-")
    log = os.path.join(FUZZ, ".build", f"{target}.log")
    started = time.time()
    with open(log, "w") as out:
        # The scratch directory comes first, so new inputs land there; the committed corpus seeds
        # the run. Fork mode runs from the working directory, so that is the scratch one too.
        subprocess.run([os.path.join(BIN, target), f"-fork={jobs}", f"-max_total_time={seconds}",
                        f"-artifact_prefix={crashes}/", *COMMON, scratch, corpus],
                       cwd=scratch, stdout=out, stderr=subprocess.STDOUT)
        merged = subprocess.run([os.path.join(BIN, target), "-merge=1", *COMMON, corpus, scratch],
                                cwd=scratch, stdout=out, stderr=subprocess.STDOUT)
    shutil.rmtree(scratch, ignore_errors=True)
    new_crashes = sorted(set(os.listdir(crashes)) - before)
    stats = {}
    with open(log, errors="replace") as f:
        for line in f:
            if line.startswith("stat::"):
                key, _, value = line[6:].partition(":")
                stats[key.strip()] = value.strip()
            if "cov:" in line and "#" in line:
                stats["last"] = line.strip()
    coverage = stats.get("last", "").split("cov:")[1].split()[0] if "cov:" in stats.get("last", "") else "?"
    summary = (f"{target:<30} {time.time() - started:5.0f} s  coverage {coverage:>5}  corpus {len(os.listdir(corpus)):>4}"
               + ("" if merged.returncode == 0 else "  (merge failed)"))
    if new_crashes:
        summary += f"\n    {len(new_crashes)} crash(es) in Fuzz/Crashes/{target}/, log {os.path.relpath(log, ROOT)}"
    return summary, bool(new_crashes)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("run")
    p.add_argument("targets", nargs="*")
    p.add_argument("-t", "--seconds", type=int, default=60)
    p.add_argument("-j", "--jobs", type=int, default=0, help="workers per target (default: cores / targets)")
    p = sub.add_parser("regress")
    p.add_argument("targets", nargs="*")
    p = sub.add_parser("repro")
    p.add_argument("target")
    p.add_argument("input")
    args = parser.parse_args()

    known = targets()
    chosen = getattr(args, "targets", None) or ([args.target] if args.command == "repro" else known)
    unknown = set(chosen) - set(known)
    if unknown:
        sys.exit(f"No such targets: {', '.join(sorted(unknown))}; there are {', '.join(known)}")
    build()

    if args.command == "run":
        jobs = args.jobs or max(1, (os.cpu_count() or 4) // len(chosen))
        print(f"Fuzzing {len(chosen)} target(s) for {args.seconds} s, {jobs} worker(s) each", flush=True)
        with ThreadPoolExecutor(max_workers=len(chosen)) as pool:
            results = list(pool.map(lambda t: run(t, args.seconds, jobs), chosen))
        for summary, _ in results:
            print(summary)
        sys.exit(1 if any(crashed for _, crashed in results) else 0)

    if args.command == "regress":
        failed = False
        for target in chosen:
            corpus = os.path.join(FUZZ, "Corpus", target)
            files = glob.glob(os.path.join(corpus, "*"))
            if not files:
                print(f"{target:<30} no corpus")
                continue
            # Given files rather than a directory, libFuzzer runs each one once and stops.
            result = subprocess.run([os.path.join(BIN, target), *COMMON, *files], capture_output=True, text=True)
            failed |= result.returncode != 0
            print(f"{target:<30} {len(files):>4} inputs  " + ("ok" if result.returncode == 0 else "FAILED\n" + result.stderr[-2000:]))
        sys.exit(1 if failed else 0)

    if args.command == "repro":
        binary = os.path.join(BIN, args.target)
        subprocess.run([binary, *COMMON, args.input])
        minimized = args.input + ".min"
        subprocess.run([binary, "-minimize_crash=1", "-runs=20000", f"-exact_artifact_path={minimized}", args.input],
                       capture_output=True)
        if os.path.exists(minimized):
            print(f"\nMinimized to {os.path.getsize(minimized)} bytes: {os.path.relpath(minimized, ROOT)}")


if __name__ == "__main__":
    main()
