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
N = 100_000
M = 2_000
s4 = G(False, list(range(M)), [(0, i) for i in range(1, M)])
t=time.time()
e = ref.eigenvector_model(s4, None, tol=1e-15, maxit=2_000_000)
show("S11 star2000 eigen limit [hub, leaf]", [e[0], e[1]]); print(time.time()-t)
e2 = ref.eigenvector_model(s4, None, tol=1e-12, maxit=10_000)
print("S11 tol1e-12 max diff", max(abs(a-b) for a, b in zip(e, e2)))
e3 = ref.eigenvector_model(s4, None)
print("S11 defaults nil?", e3 is None)
cyc = G(False, list(range(N)), [(i, (i + 1) % N) for i in range(N)])
ec = ref.eigenvector_model(cyc, None)
show("S12 cycle eigen defaults [0, 99999]", [ec[0], ec[99999]])
print("1/sqrt(N)", repr(1/math.sqrt(N)))
