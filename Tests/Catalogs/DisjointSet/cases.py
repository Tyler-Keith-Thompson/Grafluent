"""Prints the exact expected values used in test-catalog-disjoint-set.md."""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ref import DS  # noqa: E402


def show(title, d):
    print(f"--- {title}")
    print("  find  :", d.reps())
    print("  sets  :", d.subsets(), " setCount", d.sets, " count", len(d))
    print("  labels:", d.labeling())
    print("  sizes :", [d.set_size(x) for x in range(len(d))] if len(d) <= 24 else "...")


def seq(n, pairs, title):
    d = DS(n)
    rs = [d.union(a, b) for a, b in pairs]
    print(f"--- {title}: union results {rs}")
    show(title, d)
    return d


# petgraph uf_test (tests/unionfind.rs:10-35)
seq(8, [(0, 1), (1, 3), (1, 4), (4, 7), (5, 6)], "petgraph uf_test")

# petgraph labeling (tests/unionfind.rs:167-180)
d = DS(48)
for i in range(24):
    d.union(i + 1, i)
for i in range(25, 47):
    d.union(i, i + 1)
print("--- petgraph labeling: before joining, sets", d.sets, "reps", sorted(set(d.reps())))
d.union(23, 25); d.union(24, 23)
print("    after: setCount", d.sets, "reps", sorted(set(d.reps())), "labels all 0:", all(l == 0 for l in d.labeling()))

# Boost disjoint_set_test.cpp:28-55
d = DS(4)
d.union(0, 1); d.union(2, 3)
a, b = d.find(0), d.find(2)
print("--- boost test: a", a, "b", b, "find(3)", d.find(3), "union(a,b)", d.union(a, b), "setCount", d.sets, "reps", d.reps())

# Boost example disjoint_sets.cpp
seq(6, [(0, 1), (1, 2), (3, 4)], "boost example")

# NetworkX test_subtree_union (test_unionfind.py:15-24); elements 1..5, 0 unused
seq(6, [(1, 2), (3, 4), (4, 5), (1, 5)], "nx subtree union")

# NetworkX test_unionfind_weights: union(1,4,7) etc as pairwise chains
seq(10, [(1, 4), (4, 7), (2, 5), (5, 8), (3, 6), (6, 9), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9)], "nx weights")

# NetworkX test_unbalanced_merge_weights
d = DS(10)
for p in [(1, 2), (2, 3), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9)]:
    d.union(*p)
print("--- nx unbalanced: size(1)", d.set_size(1), "size(4)", d.set_size(4), "find(4) before", d.find(4), "find(1) before", d.find(1))
d.union(1, 4)
print("    after union(1,4): find(1)", d.find(1), "size", d.set_size(1), "reps", d.reps())

# JGraphT UnionFindTest.testUnionFind (aaa..eee = 0..4)
d = DS(5)
log = []
for p in [(0, 1), (2, 3), (2, 4), (2, 4), (0, 4)]:
    r = d.union(*p); log.append((p, r, d.sets))
print("--- jgrapht:", log, "reps", d.reps())
x = d.make_set()
print("    makeSet ->", x, "setCount", d.sets, "count", len(d))

# LEMON unionfind_test.cc:36-73 (UnionFindEnum), items 1..10, 0 unused
d = DS(11)
r = []
r.append(d.union(1, 2))
r += [d.union(1, 4), d.union(2, 4), d.union(3, 5)]
d.union(8, 5)  # insert(n[8], find(n[5]))
s1 = [d.set_size(x) for x in (4, 5, 6, 2)]
d.union(10, 9)  # insert(n[9]); insert(n[10], find(n[9]))
r.append(d.union(8, 10))
s2 = [d.set_size(x) for x in (4, 9, 8)]
print("--- lemon: joins", r, "sizes(4,5,6,2)", s1, "sizes(4,9,8)", s2, "sets", d.subsets(), "reps", d.reps(), "setCount", d.sets)

# Representative rules
print("--- tie: union(3,1) on 4 ->", (lambda d: (d.union(3, 1), d.reps()))(DS(4)))
print("--- tie: union(1,3) on 4 ->", (lambda d: (d.union(1, 3), d.reps()))(DS(4)))
d = DS(8); d.union(5, 6); d.union(6, 7); d.union(0, 5)
print("--- larger wins: {5,6,7} + {0} -> reps", d.reps())
d = DS(4); d.union(0, 1); d.union(2, 3); d.union(3, 1)
print("--- equal size 2+2 union(3,1) -> reps", d.reps())
A = DS(3); A.union(1, 2); A.union(0, 1)
B = DS(3); B.union(0, 1); B.union(1, 2)
print("--- same partition, different reps: A", A.reps(), A.labeling(), " B", B.reps(), B.labeling())
d = DS(5); d.union(3, 0); d.union(4, 1)
print("--- labeling example:", d.labeling(), d.subsets(), d.reps())

# scipy test_linear_union_sequence (test_disjoint_set.py:96-117)
for n in (10, 100):
    for direction in ("forwards", "backwards"):
        d = DS(n)
        idx = list(range(n - 1))
        if direction == "backwards":
            idx = idx[::-1]
        counts = []
        for it, i in enumerate(idx):
            assert d.union(i, i + 1)
            counts.append(d.sets)
        print(f"--- scipy linear n={n} {direction}: reps set {sorted(set(d.reps()))}, counts {counts[:3]}..{counts[-1]}, union(0,n-1) {d.union(0, n - 1)}")

# scipy test_equal_size_ordering n=10 (test_disjoint_set.py:136-154)
for n in (10,):
    rng = np.random.RandomState(seed=0)
    indices = np.arange(n); rng.shuffle(indices)
    pairs = [(int(indices[i]), int(indices[i + 1])) for i in range(0, n, 2)]
    for order in ("ab", "ba"):
        d = DS(n)
        for a, b in pairs:
            if order == "ba":
                a, b = b, a
            assert d.union(a, b)
        print(f"--- scipy equal size n=10 order {order}: pairs {pairs} reps {d.reps()}")

# scipy test_binary_tree (test_disjoint_set.py:157-176), kmax = 5
for kmax in (5, 10):
    n = 2 ** kmax
    rng = np.random.RandomState(seed=0)
    d = DS(n)
    ok = True
    picks = []
    for k in 2 ** np.arange(kmax):
        k = int(k)
        for i in range(0, n, 2 * k):
            r1, r2 = rng.randint(0, k, size=2)
            a, b = i + int(r1), i + k + int(r2)
            if kmax == 5 and k == 1:
                picks.append((a, b))
            assert d.union(a, b)
        expected = [x - x % (2 * k) for x in range(n)]
        ok &= d.reps() == expected
    print(f"--- scipy binary tree kmax={kmax}: reps law ok {ok}; first-round picks {picks[:4]}")

# scipy test_subsets n=10 (test_disjoint_set.py:179-199)
n = 10
rng = np.random.RandomState(seed=0)
pairs = [(int(i), int(j)) for i, j in rng.randint(0, n, (n, 2))]
d = DS(n)
trace = []
for x, y in pairs:
    r = d.union(x, y)
    trace.append((x, y, r, d.subsets()))
print("--- scipy subsets n=10 pairs", pairs)
for t in trace:
    print("    ", t)
print("    final reps", d.reps(), "labels", d.labeling(), "sizes", [d.set_size(x) for x in range(n)])

# binomial tree by root unions, n = 2^20
n = 1 << 20
d = DS(n)
k = 1
while k < n:
    for i in range(0, n, 2 * k):
        d.union(i, i + k)
    k *= 2
depth = 0
x = n - 1
while d.p[x] >= 0:
    x = d.p[x]; depth += 1
print("--- binomial 2^20: depth of n-1 before any find", depth, "setCount", d.sets, "find(n-1)", d.find(n - 1))

# chains 10^6
n = 10 ** 6
d = DS(n)
assert all(d.union(i, i + 1) for i in range(n - 1))
print("--- chain fwd 1e6: setCount", d.sets, "reps", set(d.reps()), "size", d.set_size(0))
d = DS(n)
assert all(d.union(i, i + 1) for i in range(n - 2, -1, -1))
print("--- chain bwd 1e6: setCount", d.sets, "reps", set(d.reps()))
d = DS(n)
assert all(d.union(i + 1, i) for i in range(n - 1))
print("--- chain fwd reversed args 1e6: reps", set(d.reps()))
# star: union(0, i)
d = DS(n)
assert all(d.union(i, 0) for i in range(1, n))
print("--- star 1e6: reps", set(d.reps()))
# pairs then pairs of pairs: union(2i, 2i+1) then union(2i+1, 2i+3)...
