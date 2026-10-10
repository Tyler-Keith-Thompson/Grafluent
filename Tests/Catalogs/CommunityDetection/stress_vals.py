"""Computes the literals of CommunityDetectionStressTests.swift with ref.py's model. Run like ref.py."""
import sys, time, random
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref

def und(n, ends): return ref.G(False, list(range(n)), ends)
def dirg(n, ends): return ref.G(True, list(range(n)), ends)

def cliques(k, s, ring=False):
    ends = []
    for c in range(k):
        b = c * s
        ends += [(b + i, b + j) for i in range(s) for j in range(i + 1, s)]
    if ring:
        ends += [(c * s + s - 1, ((c + 1) % k) * s) for c in range(k)]
    return ends

def show(name, labels, g, w=None):
    groups = ref.canonical(labels)
    q = ref.modularity_model(g, [1.0]*g.m if w is None else w, labels, 1.0)
    sizes = sorted(set(map(len, groups)))
    print(name, "count", len(groups), "sizes", sizes, "Q", repr(q), "first", groups[:3])

t = time.time()
g = und(100000, cliques(25000, 4))
lab = ref.louvain_model(g, None); show("S1 louvain 25000 K4", lab, g); print(time.time()-t)
t = time.time()
g = und(5000, cliques(1000, 5, ring=True))
lab = ref.louvain_model(g, None); show("S2 louvain ring 1000 K5", lab, g); print(time.time()-t)
t = time.time()
g = und(2000, cliques(400, 5, ring=True))
lab = ref.greedy_model(g, None); show("S3 greedy ring 400 K5", lab, g); print(time.time()-t)
t = time.time()
g = und(100000, cliques(20000, 5))
lab = ref.semisync_model(g, None); show("S4 semisync 20000 K5", lab, g); print(time.time()-t)
t = time.time()
lab = ref.async_model(g, None); show("S5 async 20000 K5", lab, g); print(time.time()-t)
t = time.time()
ends = []
for c in range(10000):
    b = 3*c
    ends += [(b, b+1), (b+1, b+2), (b+2, b)]
g = dirg(30000, ends)
lab = ref.louvain_model(g, None); show("S7 directed louvain 10000 C3", lab, g); print(time.time()-t)
t = time.time()
lab = ref.greedy_model(dirg(3000, ends[:3000]), None); show("S7b directed greedy 1000 C3", lab, dirg(3000, ends[:3000])); print(time.time()-t)
