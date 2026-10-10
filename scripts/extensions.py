#!/usr/bin/env python3
"""The cross-module extension index in the umbrella's documentation.

DocC lists the members a module adds to another module's type only on the extending module's
pages, so `Graph`'s page cannot show what Centrality, ShortestPaths and the rest add to it. This
writes one article per extended type into Sources/Grafluent/Grafluent.docc/Extensions/, with a
topic group for each module that extends it. The umbrella depends on every module, so its links
resolve into all of them in the combined documentation.

    python3 scripts/extensions.py
    python3 scripts/extensions.py --swift "env -u TOOLCHAINS xcrun --toolchain default swift"

It reads the symbol graphs `swift package dump-symbol-graph` writes, with extension blocks, the
same graphs DocC builds from. Bazel's //:docs (which `just docs` and the DocC workflow
build) runs it on its own symbol graphs, into a copy of the catalog; the output is not committed.
"""

import argparse
import glob
import json
import os
import re
import shlex
import shutil
import subprocess
import sys

from modules import MODULES

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(ROOT, "Sources", "Grafluent", "Grafluent.docc")
OUT = os.path.join(CATALOG, "Extensions")
LIBRARIES = {m[0] for m in MODULES}


def dump_symbol_graphs(swift, scratch_path):
    cmd = shlex.split(swift) + ["package"]
    if scratch_path:
        cmd += ["--scratch-path", scratch_path]
    cmd += ["dump-symbol-graph", "--emit-extension-block-symbols"]
    result = subprocess.run(cmd, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if result.returncode != 0:
        sys.exit(result.stdout + f"\n{shlex.join(cmd)} failed")
    m = re.search(r"Files written to (.+)", result.stdout)
    if not m:
        sys.exit(result.stdout + "\ndump-symbol-graph did not say where it wrote the symbol graphs")
    return m.group(1).strip()


def disambiguation_hash(usr):
    """DocC's hash suffix for a symbol: 32-bit FNV-1 of the USR, folded to 24 bits, base 36."""
    h = 2166136261
    for byte in usr.encode():
        h = ((h * 16777619) & 0xFFFFFFFF) ^ byte
    h = ((h >> 24) ^ h) & 0xFFFFFF
    digits = "0123456789abcdefghijklmnopqrstuvwxyz"
    s = ""
    while h:
        h, r = divmod(h, 36)
        s = digits[r] + s
    return s or "0"


def collect(directory):
    """{(extended module, type path): {extending module: [(link, sort key)]}}"""
    found = {}
    for path in sorted(glob.glob(os.path.join(directory, "*@*.symbols.json"))):
        module, extended = os.path.basename(path)[: -len(".symbols.json")].split("@")
        if module not in LIBRARIES or extended not in LIBRARIES:
            continue
        with open(path) as f:
            graph = json.load(f)
        symbols = {s["identifier"]["precise"]: s for s in graph["symbols"]}
        blocks = {s: symbols[s]["pathComponents"] for s in symbols if symbols[s]["kind"]["identifier"] == "swift.extension"}
        members = [
            symbols[r["source"]]
            for r in graph["relationships"]
            if r["kind"] == "memberOf" and r["target"] in blocks and r["source"] in symbols
        ]
        # Overloads share a path; DocC tells them apart by hash.
        counts = {}
        for s in members:
            key = tuple(s["pathComponents"])
            counts[key] = counts.get(key, 0) + 1
        for s in members:
            components = s["pathComponents"]
            link = "/".join(["", module, extended] + components)
            if counts[tuple(components)] > 1:
                link += "-" + disambiguation_hash(s["identifier"]["precise"])
            entry = (link, (components[-1].lower(), link))
            found.setdefault((extended, tuple(components[:-1])), {}).setdefault(module, []).append(entry)
    return found


def article_name(extended, type_path):
    return "-".join([extended] + list(type_path)) + "-Extensions"


def write(found):
    shutil.rmtree(OUT, ignore_errors=True)
    os.makedirs(OUT)
    order = [m[0] for m in MODULES]
    keys = sorted(found, key=lambda k: (order.index(k[0]), k[1]))
    for extended, type_path in keys:
        name = ".".join(type_path)
        lines = [
            f"# Extensions to {name}",
            "",
            f"Members other modules add to ``{'/'.join(['', extended] + list(type_path))}``.",
            "",
            "## Topics",
        ]
        for module in sorted(found[(extended, type_path)], key=order.index):
            lines += ["", f"### {module}", ""]
            entries = sorted(found[(extended, type_path)][module], key=lambda e: e[1])
            lines += [f"- ``{link}``" for link, _ in entries]
        with open(os.path.join(OUT, article_name(extended, type_path) + ".md"), "w") as f:
            f.write("\n".join(lines) + "\n")
    lines = [
        "# Extensions Across Modules",
        "",
        "The members each module adds to types declared in another module, by extended type.",
        "",
        "## Overview",
        "",
        "A type's own page lists only the members of its own module. Each page here collects the",
        "members that every other module adds to one type.",
        "",
        "## Topics",
    ]
    module = None
    for extended, type_path in keys:
        if extended != module:
            lines += ["", f"### {extended}", ""]
            module = extended
        lines.append(f"- <doc:{article_name(extended, type_path)}>")
    with open(os.path.join(OUT, "Extensions.md"), "w") as f:
        f.write("\n".join(lines) + "\n")
    return len(keys)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--swift", default="swift", help="the swift command (default: swift)")
    parser.add_argument("--scratch-path", help="passed to swift package")
    # Bazel's //:docs (tools/docc.bzl) has the symbol graphs already, and writes into a copy of
    # the catalog.
    parser.add_argument("--symbol-graph-dir", help="read these symbol graphs instead of dumping them")
    parser.add_argument("--catalog", help="the catalog to write into (default: the umbrella's)")
    args = parser.parse_args()
    global OUT
    if args.catalog:
        OUT = os.path.join(os.path.abspath(args.catalog), "Extensions")
    found = collect(args.symbol_graph_dir or dump_symbol_graphs(args.swift, args.scratch_path))
    n = write(found)
    print(f"Wrote {n} extension pages to {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
