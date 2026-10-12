#!/usr/bin/env python3
"""Cross-language comparison: Grafluent against petgraph, rustworkx-core, the Boost Graph Library,
LEMON and igraph on identical instances. See README.md.

    python3 Benchmarks/CrossLanguage/run.py                 # full sizes, 5 runs per case
    python3 Benchmarks/CrossLanguage/run.py --scale smoke --repeat 3
    python3 Benchmarks/CrossLanguage/run.py --only dijkstra bfs --libs grafluent bgl

Steps: check the toolchains, fetch LEMON 1.3.1 into .deps/ if missing, generate the instances
(data/<scale>/, once), build every harness optimized, run each (library, algorithm, instance) case
in its own process `--repeat` times, check that the libraries agree, and write one markdown table
to results/<timestamp>-<scale>.md (also printed).
"""
import argparse
import datetime
import os
import platform
import shutil
import statistics
import subprocess
import sys
import tarfile
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
BUILD = os.path.join(HERE, "build")
DEPS = os.path.join(HERE, ".deps")
LEMON_VERSION = "1.3.1"
LEMON_URL = f"http://lemon.cs.elte.hu/pub/sources/lemon-{LEMON_VERSION}.tar.gz"
LEMON_SHA256 = "71b7c725f4c0b4a8ccb92eb87b208701586cf7a96156ebd821ca3ed855bad3c8"
SWIFT = ["env", "-u", "TOOLCHAINS", "xcrun", "--toolchain", "default", "swift"]

LIBS = ["grafluent", "petgraph", "rustworkx-core", "bgl", "lemon", "igraph"]
LIB_TITLES = {"grafluent": "Grafluent", "petgraph": "petgraph", "rustworkx-core": "rustworkx-core",
              "bgl": "BGL", "lemon": "LEMON", "igraph": "igraph"}

# (algorithm, instances). Directed algorithms read each edge line as an arc; undirected ones as an
# edge. See gen.py for the instances.
CASES = [
    ("build-directed", ["gnm-1e5", "gnm-1e6", "grid-1e6", "ba-1e6"]),
    ("build-undirected", ["gnm-1e5", "gnm-1e6", "grid-1e6", "ba-1e6"]),
    ("bfs", ["gnm-1e5", "gnm-1e6", "grid-1e6", "ba-1e6"]),
    ("dfs", ["gnm-1e5", "gnm-1e6", "grid-1e6", "ba-1e6"]),
    ("cc", ["gnm-1e6", "grid-1e6", "ba-1e6", "art-sparse"]),
    ("scc", ["gnm-1e5", "gnm-1e6", "ba-1e6"]),
    ("dijkstra", ["gnm-1e5", "gnm-1e6", "grid-1e6", "ba-1e6"]),
    ("bellman-ford", ["gnm-1e5", "grid-1e5", "ba-1e5"]),
    ("mst-kruskal", ["gnm-1e5", "gnm-1e6", "grid-1e6", "ba-1e6"]),
    ("mst-prim", ["gnm-1e5", "gnm-1e6", "grid-1e6", "ba-1e6"]),
    ("topo", ["dag-1e5", "dag-1e6", "grid-1e6"]),
    ("maxflow-pr", ["flow-random", "flow-genrmf-long", "flow-genrmf-wide", "flow-vision"]),
    ("maxflow-value", ["flow-random", "flow-genrmf-long", "flow-genrmf-wide", "flow-vision"]),
    ("maxflow-dinic", ["flow-random", "flow-genrmf-long", "flow-genrmf-wide", "flow-vision"]),
    ("matching", ["match-gnm"]),
    ("bip-matching", ["match-bip"]),
    ("iso", ["iso-gnm", "iso-grid"]),
    ("bc", ["bc-gnm", "bc-ba"]),
    ("pagerank", ["pr-gnm", "gnm-1e6"]),
    ("triangles", ["gnm-1e6", "ba-1e5", "ba-1e6"]),
    ("transitivity", ["gnm-1e6", "ba-1e6"]),
    ("articulation", ["art-sparse", "grid-1e6", "ba-1e6"]),
    ("bridges", ["art-sparse", "grid-1e6", "ba-1e6"]),
    ("fw", ["fw-gnm"]),
]

ALGORITHM_TITLES = {
    "build-directed": "build, directed", "build-undirected": "build, undirected",
    "bfs": "BFS from 0", "dfs": "DFS from 0", "cc": "connected components",
    "scc": "strongly connected components", "dijkstra": "Dijkstra from 0",
    "bellman-ford": "Bellman–Ford from 0", "mst-kruskal": "MST, Kruskal", "mst-prim": "MST, Prim",
    "topo": "topological sort", "maxflow-pr": "max flow, push–relabel (full flow)",
    "maxflow-value": "max flow value (preflow phase)", "maxflow-dinic": "max flow, Dinic",
    "matching": "max matching, general", "bip-matching": "max matching, bipartite",
    "iso": "isomorphism (decision)", "bc": "betweenness", "pagerank": "PageRank",
    "triangles": "triangle count", "transitivity": "transitivity", "articulation": "articulation points",
    "bridges": "bridges", "fw": "Floyd–Warshall",
}

# Cases not run at full size, with the reason (measured, not guessed).
SKIP_FULL = {
    ("igraph", "iso", "iso-grid"): "igraph_isomorphic_vf2 grows explosively on grids (45 ms at 30×30, 21 s at 40×40, "
                                   "over 120 s at 50×50); 100×100 would only hit the timeout",
}

# Checks compared as floats, with a relative tolerance; everything else must match exactly.
FLOAT_CHECKS = {"bc": 1e-6, "pagerank": 1e-4, "transitivity": 1e-9}


def log(*a):
    print(*a, file=sys.stderr, flush=True)


def sh(cmd, cwd=None, env=None, timeout=3600):
    log("$", " ".join(cmd))
    subprocess.run(["perl", "-e", f"alarm {timeout}; exec @ARGV", *cmd], cwd=cwd, env=env, check=True)


def brew_prefix(formula):
    try:
        return subprocess.run(["brew", "--prefix", formula], capture_output=True, text=True, check=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return None


def tool_versions():
    v = {}

    def out(cmd):
        try:
            return subprocess.run(cmd, capture_output=True, text=True, timeout=60).stdout.strip()
        except (OSError, subprocess.SubprocessError):
            return "missing"
    v["swift"] = out(SWIFT + ["--version"]).splitlines()[0] if out(SWIFT + ["--version"]) else "missing"
    v["rustc"] = out(["rustc", "--version"])
    v["clang"] = out(["xcrun", "clang", "--version"]).splitlines()[0]
    for formula in ("boost", "igraph"):
        v[formula] = out(["brew", "list", "--versions", formula]) or "missing"
    v["lemon"] = LEMON_VERSION
    lock = os.path.join(HERE, "rust", "Cargo.lock")
    if os.path.exists(lock):
        text = open(lock).read()
        for crate in ("petgraph", "rustworkx-core"):
            i = text.find(f'name = "{crate}"')
            if i >= 0:
                j = text.find("version = ", i)
                v[crate] = text[j + 11:text.find('"', j + 11)]
    return v


def setup():
    missing = [f for f in ("boost", "igraph") if not brew_prefix(f)]
    if missing:
        sh(["brew", "install", *missing])
    for tool in ("cargo", "xcrun"):
        if not shutil.which(tool):
            sys.exit(f"{tool} not found: install Rust (rustup) and the Xcode command line tools")
    lemon = os.path.join(DEPS, f"lemon-{LEMON_VERSION}")
    if not os.path.exists(os.path.join(lemon, "lemon", "config.h")):
        os.makedirs(DEPS, exist_ok=True)
        tarball = os.path.join(DEPS, f"lemon-{LEMON_VERSION}.tar.gz")
        if not os.path.exists(tarball):
            log(f"fetching {LEMON_URL}")
            urllib.request.urlretrieve(LEMON_URL, tarball)
        import hashlib
        digest = hashlib.sha256(open(tarball, "rb").read()).hexdigest()
        if digest != LEMON_SHA256:
            sys.exit(f"{tarball}: sha256 {digest}, expected {LEMON_SHA256}")
        with tarfile.open(tarball) as t:
            t.extractall(DEPS)
        # LEMON's CMake script no longer configures with current CMake; the graph algorithms are
        # header-only apart from base.cc, so write the one generated header by hand.
        with open(os.path.join(lemon, "lemon", "config.h"), "w") as f:
            f.write(f'#define LEMON_VERSION "{LEMON_VERSION}"\n#define LEMON_HAVE_LONG_LONG 1\n')
    return lemon


def build(libs, lemon):
    os.makedirs(BUILD, exist_ok=True)
    boost = brew_prefix("boost")
    igraph = brew_prefix("igraph")
    if "grafluent" in libs:
        sh(SWIFT + ["build", "-c", "release", "--package-path", os.path.join(HERE, "swift")], timeout=3600)
    if "petgraph" in libs or "rustworkx-core" in libs:
        sh(["cargo", "build", "--release", "--manifest-path", os.path.join(HERE, "rust", "Cargo.toml")])
    if "bgl" in libs:
        sh(["xcrun", "clang++", "-O3", "-DNDEBUG", "-std=c++17", f"-I{boost}/include",
            os.path.join(HERE, "cpp", "bgl.cpp"), "-o", os.path.join(BUILD, "cross-bgl")])
    if "lemon" in libs:
        sh(["xcrun", "clang++", "-O3", "-DNDEBUG", "-std=c++14", "-w", f"-I{lemon}",
            os.path.join(HERE, "cpp", "lemon.cpp"), os.path.join(lemon, "lemon", "base.cc"),
            "-o", os.path.join(BUILD, "cross-lemon")])
    if "igraph" in libs:
        sh(["xcrun", "clang", "-O3", "-DNDEBUG", "-std=gnu11", f"-I{igraph}/include/igraph",
            os.path.join(HERE, "c", "igraph.c"), f"-L{igraph}/lib", "-ligraph",
            "-o", os.path.join(BUILD, "cross-igraph")])


def command(lib, algorithm, path, repeat):
    swift_bin = os.path.join(HERE, "swift", ".build", "release", "CrossGrafluent")
    rust_bin = os.path.join(HERE, "rust", "target", "release", "cross-rust")
    return {
        "grafluent": [swift_bin, algorithm, path, str(repeat)],
        "petgraph": [rust_bin, "petgraph", algorithm, path, str(repeat)],
        "rustworkx-core": [rust_bin, "rustworkx-core", algorithm, path, str(repeat)],
        "bgl": [os.path.join(BUILD, "cross-bgl"), algorithm, path, str(repeat)],
        "lemon": [os.path.join(BUILD, "cross-lemon"), algorithm, path, str(repeat)],
        "igraph": [os.path.join(BUILD, "cross-igraph"), algorithm, path, str(repeat)],
    }[lib]


def run_case(lib, algorithm, path, repeat, timeout):
    """[(representation, check, median ms, [ms])], or a string saying why there is none."""
    env = dict(os.environ, RAYON_NUM_THREADS="1")
    try:
        p = subprocess.run(command(lib, algorithm, path, repeat), capture_output=True, text=True, timeout=timeout, env=env)
    except subprocess.TimeoutExpired:
        return f"timeout (>{timeout} s)"
    if p.returncode != 0:
        return f"failed (exit {p.returncode}): {(p.stderr or p.stdout).strip().splitlines()[-1:] or ''}"
    results = []
    for line in p.stdout.splitlines():
        if line.startswith("NA"):
            return "n/a: " + line[3:].strip()
        if line.startswith("RESULT "):
            body = line[len("RESULT "):]
            rest, times = body.rsplit(" ", 1)
            rep, check = rest.rsplit(" ", 1)
            ms = [float(x) for x in times.split(",")]
            results.append((rep, check, statistics.median(ms), ms))
    return results or f"no output: {p.stdout.strip()[:200]}"


def agree(algorithm, a, b):
    if algorithm in FLOAT_CHECKS:
        x, y = float(a), float(b)
        return abs(x - y) <= FLOAT_CHECKS[algorithm] * max(abs(x), abs(y), 1e-300)
    return a == b


def fmt_ms(ms):
    if ms >= 100:
        return f"{ms:.0f}"
    if ms >= 10:
        return f"{ms:.1f}"
    if ms >= 1:
        return f"{ms:.2f}"
    return f"{ms:.3f}"


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--scale", choices=["full", "smoke"], default="full")
    p.add_argument("--repeat", type=int, default=5, help="runs per case; the median is reported")
    p.add_argument("--timeout", type=int, default=900, help="seconds per (library, case) process")
    p.add_argument("--only", nargs="*", help="algorithms to run")
    p.add_argument("--instances", nargs="*", help="instances to run")
    p.add_argument("--libs", nargs="*", default=LIBS, choices=LIBS)
    p.add_argument("--no-build", action="store_true")
    args = p.parse_args()

    load_start = os.getloadavg()
    started = datetime.datetime.now()
    lemon = setup()
    data = os.path.join(HERE, "data", args.scale)
    sh([sys.executable, os.path.join(HERE, "gen.py"), "--scale", args.scale, "--out", data])
    if not args.no_build:
        build(args.libs, lemon)
    versions = tool_versions()
    sys.path.insert(0, HERE)
    import gen
    descriptions = {name: desc for name, (desc, _) in gen.instances(args.scale).items()}

    rows, problems = [], []
    for algorithm, instances in CASES:
        if args.only and algorithm not in args.only:
            continue
        for instance in instances:
            if args.instances and instance not in args.instances:
                continue
            path = os.path.join(data, f"{instance}.txt")
            cells = {}
            for lib in args.libs:
                log(f"{algorithm} {instance} {lib}")
                skip = SKIP_FULL.get((lib, algorithm, instance)) if args.scale == "full" else None
                cells[lib] = f"n/a: {skip}" if skip else run_case(lib, algorithm, path, args.repeat, args.timeout)
            # Agreement: every representation of every library against the answer most of them gave.
            answers = [(lib, rep, check) for lib, r in cells.items() if isinstance(r, list) for rep, check, _, _ in r]
            reference = max((x[2] for x in answers), key=lambda c: sum(agree(algorithm, c, y[2]) for y in answers)) if answers else None
            mismatched = set()
            for lib, rep, check in answers:
                if not agree(algorithm, reference, check):
                    mismatched.add(lib)
            if mismatched:
                problems.append(f"{algorithm} on {instance}: " + "; ".join(f"{lib} {rep} = {check}" for lib, rep, check in answers))
            rows.append((algorithm, instance, cells, mismatched, reference))
    load_end = os.getloadavg()

    def best(result):
        return min(result, key=lambda r: r[2]) if isinstance(result, list) and result else None

    lines = []
    lines.append(f"# Cross-language comparison ({args.scale})\n")
    lines.append(f"- Started {started:%Y-%m-%d %H:%M}, machine {platform.machine()} {platform.mac_ver()[0] or platform.platform()}, "
                 f"{os.cpu_count()} logical CPUs; median of {args.repeat} runs per case, one process per case, single-threaded.")
    lines.append(f"- Load average at start {load_start[0]:.2f} {load_start[1]:.2f} {load_start[2]:.2f}; "
                 f"at end {load_end[0]:.2f} {load_end[1]:.2f} {load_end[2]:.2f}.")
    lines.append("- Versions: " + ", ".join(f"{k} {v}" for k, v in versions.items()) + ".")
    lines.append("- Times in ms, algorithm only (the graph is built before timing, except in the build rows). "
                 "Grafluent has a column per representation (AL: AdjacencyList, or UndirectedAdjacencyList, "
                 "DirectedPseudograph or BipartiteGraph where the algorithm is undirected, flow or bipartite; "
                 "CSR: CompressedSparseRow). Another library's cell is its fastest representation, marked "
                 "* when that is not its default one (see the representations list below). "
                 "Ratio = fastest Grafluent ÷ fastest other library (below 1: Grafluent is faster).")
    lines.append("- ✗ marks a library whose answer differs from the others (details below the table).\n")
    header = ["algorithm", "instance", "Grafluent AL", "Grafluent CSR"] + [LIB_TITLES[l] for l in args.libs if l != "grafluent"] + ["ratio", "check"]
    lines.append("| " + " | ".join(header) + " |")
    lines.append("|" + "---|" * len(header))
    representations = {}
    for algorithm, instance, cells, mismatched, reference in rows:
        row = [ALGORITHM_TITLES[algorithm], f"{instance} ({descriptions.get(instance, '')})"]
        g = cells.get("grafluent")
        al = csr = None
        if isinstance(g, list):
            for rep, check, ms, _ in g:
                if rep == "CompressedSparseRow":
                    csr = ms
                else:
                    al = ms
        mark = " ✗" if "grafluent" in mismatched else ""
        row.append(fmt_ms(al) + mark if al is not None else ("—" if isinstance(g, list) else short(g)))
        row.append(fmt_ms(csr) + mark if csr is not None else "—")
        others = []
        for lib in args.libs:
            if lib == "grafluent":
                continue
            r = cells[lib]
            b = best(r)
            if b:
                default = r[0][0]
                star = "*" if b[0] != default else ""
                representations.setdefault(lib, set()).update(rep for rep, _, _, _ in r)
                row.append(fmt_ms(b[2]) + star + (" ✗" if lib in mismatched else ""))
                others.append(b[2])
            else:
                row.append(short(r))
        ours = [x for x in (al, csr) if x is not None]
        row.append(f"{min(ours) / min(others):.2f}" if ours and others else "—")
        row.append(f"`{reference}`" if reference is not None else "—")
        lines.append("| " + " | ".join(row) + " |")
    lines.append("")
    lines.append("Representations: " + "; ".join(f"{LIB_TITLES[l]}: {', '.join(sorted(r))}" for l, r in representations.items()) + ".")
    lines.append("")
    if problems:
        lines.append("## Disagreements\n")
        lines.extend(f"- {x}" for x in problems)
    else:
        lines.append("Every library that ran a case gave the same answer.")
    notes = sorted({f"{LIB_TITLES[lib]}, {alg}: {r[5:]}" for alg, _, cells, _, _ in rows for lib, r in cells.items()
                    if isinstance(r, str) and r.startswith("n/a: ")})
    if notes:
        lines.append("\n## Not available\n")
        lines.extend(f"- {x}" for x in notes)
    failures = [f"{LIB_TITLES[lib]}, {alg} on {inst}: {r}" for alg, inst, cells, _, _ in rows for lib, r in cells.items()
                if isinstance(r, str) and not r.startswith("n/a: ")]
    if failures:
        lines.append("\n## Failures and timeouts\n")
        lines.extend(f"- {x}" for x in failures)
    text = "\n".join(lines) + "\n"
    os.makedirs(os.path.join(HERE, "results"), exist_ok=True)
    out = os.path.join(HERE, "results", f"{started:%Y%m%d-%H%M%S}-{args.scale}.md")
    with open(out, "w") as f:
        f.write(text)
    print(text)
    log(f"wrote {out}")
    # Fail only when Grafluent's answer is the odd one out; another library's disagreement is
    # reported in the table (rustworkx-core's bridges is a known one, see README.md).
    return 1 if any("grafluent" in mismatched for _, _, _, mismatched, _ in rows) else 0


def short(result):
    if isinstance(result, str):
        if result.startswith("n/a"):
            return "n/a"
        if result.startswith("timeout"):
            return "timeout"
        return "failed"
    return "—"


if __name__ == "__main__":
    sys.exit(main())
