import sys, time, math
sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
import ref
G = ref.G
_orig_matrix = ref.matrix
def _rows_only(g, w):
    """ref.matrix without the dense A (same rows, same weights)."""
    wt = [1.0] * g.m if w is None else [float(x) for x in ref.weights_of(g, w, finite=True)]
    return None, [[(t, wt[ref.edge_of_rows(e)]) for t, e in g.rows[v]] for v in range(g.n)]
ref.matrix = _rows_only
def show(label, x):
    print(label, repr(x) if not isinstance(x, list) else [repr(v) for v in x])
g = ref.parse_graph("U: grid(30,30)")
assert g.vertices == list(range(900))
print("grid first edges", g.ends[:5])
bg = ref.betweenness_model(g, None, True, False)
show("S6 grid [0, 1, 31, 435, 464, 899]", [bg[i] for i in (0, 1, 31, 435, 464, 899)])
bu = ref.betweenness_model(g, None, False, False)
show("S6 grid unnormalized sum", sum(bu))
# sum of (d(s,t)-1) over unordered pairs: independent check of the sum
D = 0
n = 900
for s in range(n):
    r1, c1 = divmod(s, 30)
    for t in range(s+1, n):
        r2, c2 = divmod(t, 30)
        D += abs(r1-r2) + abs(c1-c2) - 1
print("S6 closed form sum", D)
N = 100_000
star = G(False, list(range(N)), [(0, i) for i in range(1, N)])
t=time.time()
pr = ref.pagerank_model(star, None, tol=1e-15, maxit=100000)
show("S8 star pagerank limit [hub, leaf]", [pr[0], pr[1]]); print(time.time()-t)
pr2 = ref.pagerank_model(star, None)
show("S8 star pagerank defaults [hub, leaf]", [pr2[0], pr2[1]])
dpath = G(True, list(range(N)), [(i, i + 1) for i in range(N - 1)])
t=time.time()
pp = ref.pagerank_model(dpath, None, tol=1e-15, maxit=100000)
show("S8 dpath pagerank limit [0, 1, 50, 99998, 99999]", [pp[i] for i in (0, 1, 50, 99998, 99999)]); print(time.time()-t)
pd = ref.pagerank_model(dpath, None)
print("S8 dpath defaults max diff from limit", max(abs(a-b) for a, b in zip(pp, pd)))
path = G(False, list(range(N)), [(i, i + 1) for i in range(N - 1)])
k = ref.katz_model(path, None, tol=1e-15, maxit=100000)
show("S9 path katz limit [0, 1, 2, 50000, 99999]", [k[i] for i in (0, 1, 2, 50000, 99999)])
kd = ref.katz_model(path, None)
print("S9 defaults max diff", max(abs(a-b) for a, b in zip(k, kd)))
kn = ref.katz_model(path, None, normalized=False, tol=1e-15, maxit=100000)
show("S9 path katz unnormalized limit [0, 1, 2, 50000]", [kn[i] for i in (0, 1, 2, 50000)])
dstar = G(True, list(range(N)), [(0, i) for i in range(1, N)])
hh = ref.hits_model(dstar, None, 1e-15, 2_000_000)
show("S10 dstar hits limit hubs [0, 1], auth [0, 1]", [hh[0][0], hh[0][1], hh[1][0], hh[1][1]])
hd = ref.hits_model(dstar, None)
print("S10 defaults not nil", hd is not None)
M = 10_000
s4 = G(False, list(range(M)), [(0, i) for i in range(1, M)])
t=time.time()
e = ref.eigenvector_model(s4, None, tol=1e-15, maxit=2_000_000)
show("S11 star1e4 eigen limit [hub, leaf]", [e[0], e[1]]); print(time.time()-t)
e2 = ref.eigenvector_model(s4, None, tol=1e-12, maxit=10_000)
print("S11 tol1e-12 max diff", max(abs(a-b) for a, b in zip(e, e2)))
e3 = ref.eigenvector_model(s4, None)
print("S11 defaults nil?", e3 is None)
cyc = G(False, list(range(N)), [(i, (i + 1) % N) for i in range(N)])
ec = ref.eigenvector_model(cyc, None)
show("S12 cycle eigen defaults [0, 99999]", [ec[0], ec[99999]])
print("1/sqrt(N)", repr(1/math.sqrt(N)))
