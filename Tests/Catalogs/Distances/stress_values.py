"""Literals of DistanceStressTests.swift: the reduced-size stress rows, by ref.py's model and closed forms."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref
# Reduced-scale versions of the benchmark-only rows, by the model and the closed forms.
for n in (10000,):
    cell = f"U: [] P(0..{n-1})"
    print("path", n, "wiener closed", ref.closed(cell, "wienerIndex"), "centroid closed", ref.closed(cell, "centroid"))
    cell = f"U: [] S(0;1..{n-1})"
    print("star", n, "wiener closed", ref.closed(cell, "wienerIndex"), "centroid closed", ref.closed(cell, "centroid"))
# model check of closed forms at a smaller n where the model runs
for n in (300,):
    for c in (f"U: [] P(0..{n-1})", f"U: [] S(0;1..{n-1})"):
        for op in ("wienerIndex", "centroid"):
            assert ref.evaluate(c, op, check=False) == ref.closed(c, op)
print("closed forms agree with the model at n = 300")
# directed path of 1e5: eccentricities of 0 and 1 by the model's search
n = 100000
g = ref.parse_graph(f"D: [] P(0..{n-1})")
d0 = ref.search(g, 0, None); d1 = ref.search(g, 1, None)
print("dipath ecc(0)", max(d0), "reaches all", all(x is not None for x in d0), "ecc(1) nil:", any(x is None for x in d1))
# weighted path 1e5, weight e%3+1: eccentricity of 0 and of 50000
w = [e % 3 + 1 for e in range(n - 1)]
gu = ref.parse_graph(f"U: [] P(0..{n-1})")
d = ref.search(gu, 0, w); print("weighted path ecc(0)", max(d))
d = ref.search(gu, 50000, w); print("weighted path ecc(50000)", max(d))
# two paths of 50000 each, weighted: disconnected
g2 = ref.parse_graph(f"U: [] P(0..49999), P(50000..99999)")
print("two paths n", g2.n, "m", g2.m)
dd = ref.search(g2, 0, [1]*g2.m); print("from 0 misses", any(x is None for x in dd))
# grid 300x300 bounding
t=time.time()
gg = ref.parse_graph("U: [] grid(300,300)")
for mode in ("diameter","radius","center","periphery"):
    v,k = ref.bounding(gg, mode)
    print("grid300", mode, v if mode in ("diameter","radius") else (len(v), v[:6]), "searches", k)
print(time.time()-t)
