"""Instances for the cross-language comparison, written once and read by every harness.

Every random choice comes from the catalogs' 64-bit LCG (Knuth's MMIX constants, output x >> 33;
Tests/Catalogs/Isomorphism/ref.py `lcg_edges`, Tests/Catalogs/DirectedAcyclicGraph/timings.py),
and the flow networks are FlowsBenchmarks' generators line for line (lcgnet, genrmf, vision, with
the same seeds).

File format (text): a header line `n m s t nleft blocks`, then `blocks` blocks of m lines
`u v w`. Unused header fields are 0. `s`/`t` are the flow terminals, `nleft` the size of the left
side of a bipartite instance (left = 0..<nleft), and `blocks` is 2 for an isomorphism pair (the
graph, then a relabelled copy). Edges are listed in generation order. Except in the flow networks,
there are no self-loops and no repeated pairs, unordered: so each edge keeps its position in every
library that stores edges in insertion order, and a weight array indexed by that position stays
aligned. Directed algorithms read each line as the arc u → v; undirected ones as the edge {u, v}.

    python3 gen.py --scale full|smoke --out data/<scale>
"""
import argparse
import os
import sys

MASK = (1 << 64) - 1
FORMAT_VERSION = "1"


class LCG:
    def __init__(self, seed):
        self.x = seed & MASK

    def next(self):
        self.x = (self.x * 6364136223846793005 + 1442695040888963407) & MASK
        return self.x >> 33


def gnm(n, m, seed, wmax=1000):
    """m distinct unordered non-loop pairs over 0..<n, each with a weight 1…wmax."""
    rng, seen, out = LCG(seed), set(), []
    while len(out) < m:
        u, v = rng.next() % n, rng.next() % n
        if u == v:
            continue
        key = (u, v) if u < v else (v, u)
        if key in seen:
            continue
        seen.add(key)
        out.append((u, v, 1 + rng.next() % wmax))
    return out


def grid(side, seed, wmax=1000):
    """side × side 4-neighbour grid, each edge once, pointing right or down (so, read directed,
    a DAG whose order is row-major)."""
    rng, out = LCG(seed), []
    for r in range(side):
        for c in range(side):
            v = r * side + c
            if c + 1 < side:
                out.append((v, v + 1, 1 + rng.next() % wmax))
            if r + 1 < side:
                out.append((v, v + side, 1 + rng.next() % wmax))
    return out


def barabasi_albert(n, k, seed, wmax=1000):
    """Preferential attachment as NetworkX's barabasi_albert_graph: vertex k first joins 0..<k,
    then each new vertex joins k distinct vertices drawn from the list of endpoints so far. Each
    edge is oriented by a coin, so the directed reading is not a DAG."""
    rng, out, repeated = LCG(seed), [], []
    for v in range(k, n):
        if v == k:
            targets = list(range(k))
        else:
            chosen, targets = set(), []
            while len(targets) < k:
                x = repeated[rng.next() % len(repeated)]
                if x not in chosen:
                    chosen.add(x)
                    targets.append(x)
        for t in targets:
            w = 1 + rng.next() % wmax
            out.append((v, t, w) if rng.next() & 1 else (t, v, w))
        repeated.extend(targets)
        repeated.extend([v] * k)
    return out


def forward_pairs(n, m, seed):
    """timings.py's forward_pairs without repeats: a DAG whose order is 0, 1, …, n − 1."""
    rng, seen, out = LCG(seed), set(), []
    while len(out) < m:
        a, b = rng.next() % n, rng.next() % n
        if a == b:
            continue
        key = (min(a, b), max(a, b))
        if key in seen:
            continue
        seen.add(key)
        out.append((key[0], key[1], 1 + rng.next() % 1000))
    return out


def lcgnet(n, m, seed, cmax):
    """FlowsBenchmarks.lcgnet: repeated arcs are kept, as there."""
    rng, out = LCG(seed), []
    while len(out) < m:
        u, v = rng.next() % n, rng.next() % n
        if u == v:
            continue
        out.append((u, v, 1 + rng.next() % cmax))
    return out


def genrmf(a, b, seed, c1=1, c2=100):
    rng, out = LCG(seed), []
    big = c2 * a * a
    for k in range(b):
        base = k * a * a
        for i in range(a):
            for j in range(a):
                v = base + i * a + j
                if j + 1 < a:
                    out.append((v, v + 1, big))
                    out.append((v + 1, v, big))
                if i + 1 < a:
                    out.append((v, v + a, big))
                    out.append((v + a, v, big))
        if k + 1 < b:
            perm = list(range(a * a))
            for x in range(a * a - 1, 0, -1):
                y = rng.next() % (x + 1)
                perm[x], perm[y] = perm[y], perm[x]
            for x in range(a * a):
                out.append((base + x, base + a * a + perm[x], c1 + rng.next() % (c2 - c1 + 1)))
    return a * a * b, out


def vision(rows, cols, seed):
    rng, out = LCG(seed), []
    p = rows * cols
    for i in range(rows):
        for j in range(cols):
            v = i * cols + j
            out.append((p, v, rng.next() % 100))
            out.append((v, p + 1, rng.next() % 100))
            if j + 1 < cols:
                out.append((v, v + 1, 1 + rng.next() % 20))
                out.append((v + 1, v, 1 + rng.next() % 20))
            if i + 1 < rows:
                out.append((v, v + cols, 1 + rng.next() % 20))
                out.append((v + cols, v, 1 + rng.next() % 20))
    return p + 2, out


def bipartite(nl, nr, m, seed):
    """m distinct pairs between 0..<nl and nl..<nl+nr."""
    rng, seen, out = LCG(seed), set(), []
    while len(out) < m:
        u, v = rng.next() % nl, nl + rng.next() % nr
        if (u, v) in seen:
            continue
        seen.add((u, v))
        out.append((u, v, 1))
    return out


def relabelled(n, edges, seed):
    """The same graph under a random permutation of the vertices, edges shuffled too."""
    rng = LCG(seed)
    perm = list(range(n))
    for i in range(n - 1, 0, -1):
        j = rng.next() % (i + 1)
        perm[i], perm[j] = perm[j], perm[i]
    out = [(perm[u], perm[v], w) for u, v, w in edges]
    for i in range(len(out) - 1, 0, -1):
        j = rng.next() % (i + 1)
        out[i], out[j] = out[j], out[i]
    return out


def write(path, n, blocks, s=0, t=0, nleft=0):
    m = len(blocks[0])
    assert all(len(b) == m for b in blocks)
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write(f"{n} {m} {s} {t} {nleft} {len(blocks)}\n")
        for b in blocks:
            f.write("".join(f"{u} {v} {w}\n" for u, v, w in b))
    os.replace(tmp, path)


def instances(scale):
    """name -> (description, thunk returning (n, blocks, s, t, nleft)). The smoke scale keeps
    every shape and shrinks it about 20–100×."""
    full = scale == "full"
    I = {}

    def add(name, desc, thunk):
        I[name] = (desc, thunk)

    for tag, n, m, seed in ((("1e5", 10_000, 100_000, 1), ("1e6", 100_000, 1_000_000, 2)) if full
                            else (("1e5", 1_000, 5_000, 1), ("1e6", 5_000, 25_000, 2))):
        add(f"gnm-{tag}", f"G({n}, {m})", lambda n=n, m=m, seed=seed: (n, [gnm(n, m, seed)], 0, 0, 0))
    for tag, side, seed in ((("1e5", 224, 3), ("1e6", 708, 4)) if full else (("1e5", 30, 3), ("1e6", 60, 4))):
        add(f"grid-{tag}", f"grid {side}×{side}", lambda side=side, seed=seed: (side * side, [grid(side, seed)], 0, 0, 0))
    for tag, n, seed in ((("1e5", 20_000, 5), ("1e6", 200_000, 6)) if full else (("1e5", 1_000, 5), ("1e6", 5_000, 6))):
        add(f"ba-{tag}", f"Barabási–Albert({n}, 5)", lambda n=n, seed=seed: (n, [barabasi_albert(n, 5, seed)], 0, 0, 0))
    for tag, n, m, seed in ((("1e5", 10_000, 100_000, 7), ("1e6", 100_000, 1_000_000, 8)) if full
                            else (("1e5", 1_000, 5_000, 7), ("1e6", 5_000, 25_000, 8))):
        add(f"dag-{tag}", f"DAG forward pairs({n}, {m})", lambda n=n, m=m, seed=seed: (n, [forward_pairs(n, m, seed)], 0, 0, 0))

    # Flows: FlowsBenchmarks' families and seeds (full), or the same generators shrunk (smoke).
    rn, rm = (5000, 50000) if full else (500, 5000)
    add("flow-random", f"lcgnet({rn}, {rm}), caps 1…1000", lambda: (rn, [lcgnet(rn, rm, 11, 1000)], 0, rn - 1, 0))
    for name, (a, b, seed) in (("flow-genrmf-long", (8, 256, 12) if full else (4, 32, 12)),
                               ("flow-genrmf-wide", (32, 16, 13) if full else (8, 4, 13))):
        def g(a=a, b=b, seed=seed):
            n, e = genrmf(a, b, seed)
            return n, [e], 0, n - 1, 0
        add(name, f"genrmf a={a} b={b}", g)
    side = 256 if full else 32

    def vis(side=side):
        n, e = vision(side, side, 16)
        return n, [e], n - 2, n - 1, 0
    add("flow-vision", f"vision {side}×{side}", vis)

    mn, mm = (20_000, 60_000) if full else (2_000, 6_000)
    add("match-gnm", f"G({mn}, {mm})", lambda: (mn, [gnm(mn, mm, 42)], 0, 0, 0))
    bl, bm = (100_000, 300_000) if full else (5_000, 15_000)
    add("match-bip", f"bipartite {bl}+{bl}, {bm} edges", lambda: (2 * bl, [bipartite(bl, bl, bm, 41)], 0, 0, bl))

    iso_n, iso_m = (2000, 10_000) if full else (300, 1_500)

    def iso_gnm():
        e = gnm(iso_n, iso_m, 12)
        return iso_n, [e, relabelled(iso_n, e, 99)], 0, 0, 0
    add("iso-gnm", f"G({iso_n}, {iso_m}) vs relabelled", iso_gnm)
    iso_side = 100 if full else 20

    def iso_grid():
        e = grid(iso_side, 13)
        return iso_side * iso_side, [e, relabelled(iso_side * iso_side, e, 98)], 0, 0, 0
    add("iso-grid", f"grid {iso_side}×{iso_side} vs relabelled", iso_grid)

    bn, bm2 = (2000, 10_000) if full else (300, 1_500)
    add("bc-gnm", f"G({bn}, {bm2})", lambda: (bn, [gnm(bn, bm2, 11)], 0, 0, 0))
    add("bc-ba", f"Barabási–Albert({bn}, 5)", lambda: (bn, [barabasi_albert(bn, 5, 14)], 0, 0, 0))
    pn, pm = (100_000, 500_000) if full else (5_000, 25_000)
    add("pr-gnm", f"G({pn}, {pm})", lambda: (pn, [gnm(pn, pm, 12)], 0, 0, 0))
    an, am = (100_000, 120_000) if full else (5_000, 6_000)
    add("art-sparse", f"G({an}, {am})", lambda: (an, [gnm(an, am, 15)], 0, 0, 0))
    fn, fm = (1000, 10_000) if full else (150, 1_500)
    add("fw-gnm", f"G({fn}, {fm})", lambda: (fn, [gnm(fn, fm, 16)], 0, 0, 0))
    return I


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--scale", choices=["full", "smoke"], default="full")
    p.add_argument("--out", required=True)
    p.add_argument("--only", nargs="*")
    args = p.parse_args()
    os.makedirs(args.out, exist_ok=True)
    stamp = os.path.join(args.out, "VERSION")
    current = open(stamp).read().strip() if os.path.exists(stamp) else None
    if current != FORMAT_VERSION:
        for f in os.listdir(args.out):
            if f.endswith(".txt"):
                os.remove(os.path.join(args.out, f))
    for name, (desc, thunk) in instances(args.scale).items():
        if args.only and name not in args.only:
            continue
        path = os.path.join(args.out, f"{name}.txt")
        if os.path.exists(path):
            continue
        n, blocks, s, t, nleft = thunk()
        write(path, n, blocks, s, t, nleft)
        print(f"wrote {path}: n={n} m={len(blocks[0])} ({desc})", file=sys.stderr)
    with open(stamp, "w") as f:
        f.write(FORMAT_VERSION + "\n")


if __name__ == "__main__":
    main()
