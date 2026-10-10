"""Computes the literals of CommunityDetectionStressTests.swift with ref.py's model. Run like ref.py."""
import sys, time
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref
from collections import Counter
n = 100000
g = ref.G(False, list(range(n)), [(i, i+1) for i in range(n-1)])
t=time.time()
lab = ref.semisync_model(g, None)
gr = ref.canonical(lab)
print(len(gr), Counter(map(len, gr)), time.time()-t)
print([c for c in gr if len(c) != 2])
print(all(c == list(range(c[0], c[-1]+1)) for c in gr))
lab = ref.async_model(g, None)
gr = ref.canonical(lab)
print("async", len(gr), Counter(map(len, gr)), [c for c in gr if len(c) != 2][:5])
print(all(c == list(range(c[0], c[-1]+1)) for c in gr))
