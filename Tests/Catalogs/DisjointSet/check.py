"""Cross-checks the reference DS against scipy's DisjointSet, NetworkX's
UnionFind, and the naive oracle.
Run: uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3 check.py"""
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from ref import DS, Naive  # noqa: E402

# scipy's DisjointSet (scipy.cluster.hierarchy, from scipy/_lib/_disjoint_set.py).
from scipy.cluster.hierarchy import DisjointSet as ScipyDS  # noqa: E402

import networkx as nx  # noqa: E402

checks = 0


def same(a, b, what):
    global checks
    checks += 1
    assert a == b, f"{what}: {a!r} != {b!r}"


def run(seed, n, ops):
    global checks
    rng = random.Random(seed)
    d, z, s, u = DS(n), Naive(n), ScipyDS(range(n)), nx.utils.UnionFind(range(n))
    for _ in range(ops):
        if len(d) == 0 or rng.random() < 0.05:
            x = d.make_set(); same(z.make_set(), x, "make_set"); s.add(x); u[x]
            continue
        a, b = rng.randrange(len(d)), rng.randrange(len(d))
        kind = rng.random()
        if kind < 0.6:
            before = d.find_readonly(a) != d.find_readonly(b)
            r = d.union(a, b)
            same(r, before, "union result law (petgraph uf_rand)")
            same(z.union(a, b), r, "union vs naive")
            same(s.merge(a, b), r, "union vs scipy merge")
            u.union(a, b)
        elif kind < 0.8:
            same(d.in_same_set(a, b), s.connected(a, b), "connected")
        else:
            k = d.set_size(a)
            same(k, s.subset_size(a), "subset_size")
            same(k, z.set_size(a), "size vs naive")
        same(d.sets, s.n_subsets, "n_subsets")
        same(d.sets, z.sets, "sets vs naive")
    # exact representatives: ref == scipy == naive
    # the parent forest itself equals scipy's (same algorithm), before any further find
    same([q if q >= 0 else x for x, q in enumerate(d.p)], [s._parents[x] for x in range(len(d))], "parents vs scipy")
    same(d.reps(), [s[x] for x in range(len(d))], "reps vs scipy")
    same(d.reps(), [z.find(x) for x in range(len(d))], "reps vs naive")
    same(d.subsets(), z.subsets(), "subsets vs naive")
    same(d.subsets(), [sorted(t) for t in s.subsets()], "subsets order vs scipy")
    same(d.labeling(), z.labeling(), "labeling vs naive")
    same(sorted(map(sorted, u.to_sets())), sorted(d.subsets()), "partition vs networkx")


for seed in range(400):
    for n in (0, 1, 2, 3, 10, 50):
        run(seed * 7 + n, n, 4 * max(n, 5))
for seed in range(20):
    run(10_000 + seed, 1000, 6000)
print("all checks passed:", checks)
