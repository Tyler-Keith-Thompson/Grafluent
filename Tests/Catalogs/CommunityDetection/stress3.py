"""Computes the literals of CommunityDetectionStressTests.swift with ref.py's model. Run like ref.py."""
import sys, time
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref
from collections import Counter
n = 100000
g = ref.G(False, list(range(n)), [(i, i+1) for i in range(n-1)])
t=time.time()
lab = ref.louvain_model(g, None)
gr = ref.canonical(lab)
print("path louvain", len(gr), Counter(map(len, gr)).most_common(5), repr(ref.modularity_model(g, [1.0]*g.m, lab, 1.0)), time.time()-t, flush=True)
print([ (c[0], c[-1]) for c in gr[:5]], [(c[0], c[-1]) for c in gr[-3:]])
ok = all(c == list(range(c[0], c[-1]+1)) for c in gr); print("contiguous", ok)
t=time.time()
lab = ref.semisync_model(ref.G(False, list(range(2000)), [(i, i+1) for i in range(1999)]), None)
gr = ref.canonical(lab); print("path2000 semisync", len(gr), Counter(map(len, gr)).most_common(5), time.time()-t)
