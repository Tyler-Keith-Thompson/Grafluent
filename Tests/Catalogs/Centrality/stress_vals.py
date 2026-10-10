import sys, time
sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
import ref
from fractions import Fraction
G = ref.G
def show(label, x):
    print(label, repr(x) if not isinstance(x, list) else [repr(v) for v in x])

N = 100_000
star = G(False, list(range(N)), [(0, i) for i in range(1, N)])
d = ref.degree_model(star, "degree"); show("S1 star degree hub, leaf", [d[0], d[1]])
dstar = G(True, list(range(N)), [(0, i) for i in range(1, N)])
show("S2 dstar out hub, out leaf", [ref.degree_model(dstar, "out")[0], ref.degree_model(dstar, "out")[1]])
show("S2 dstar in hub, in leaf", [ref.degree_model(dstar, "in")[0], ref.degree_model(dstar, "in")[1]])
path = G(False, list(range(N)), [(i, i + 1) for i in range(N - 1)])
show("S3 path closeness of 0", ref.closeness_model(path, None, True, only=0))
show("S3 path closeness of 50000", ref.closeness_model(path, None, True, only=50000))
show("S3 path harmonic of 0", ref.closeness_model(path, None, False, only=0, harmonic=True))
w = [e % 3 + 1 for e in range(N - 1)]
show("S13 path weighted closeness of 0", ref.closeness_model(path, w, True, only=0))
show("S13 path weighted harmonic of 99999", ref.closeness_model(path, w, False, only=99999, harmonic=True))
M = 2000
p2 = G(False, list(range(M)), [(i, i + 1) for i in range(M - 1)])
c = ref.closeness_model(p2, None, True); h = ref.closeness_model(p2, None, False, harmonic=True)
show("S4 p2000 closeness [0, 1, 999, 1000, 1999]", [c[i] for i in (0, 1, 999, 1000, 1999)])
show("S4 p2000 harmonic [0, 1, 999, 1000, 1999]", [h[i] for i in (0, 1, 999, 1000, 1999)])
# closed forms for all entries (checked against the model)
cc = [ (M-1)/ (i*(i+1)//2 + (M-1-i)*(M-i)//2) for i in range(M)]
assert all(abs(a-b) <= 1e-15*max(1,abs(b)) for a, b in zip(c, cc)), "closeness closed form"
b = ref.betweenness_model(p2, None, False, False)
assert all(b[i] == i*(M-1-i) for i in range(M)), "betweenness closed form"
show("S5 p2000 betweenness [0, 1, 999, 1000, 1999]", [b[i] for i in (0, 1, 999, 1000, 1999)])
# grid 30x30
g = ref.parse_graph("U: grid(30,30)")
t = time.time(); bg = ref.betweenness_model(g, None, True, False); 
show("S6 grid30 betweenness all", bg)
# exact check with fractions via brute counting (integers)
def exact_grid(g):
    n = g.n; rows = ref.search_rows(g, False)
    bc = [Fraction(0)] * n
    for s in range(n):
        dist = [None]*n; sig = [0]*n; dist[s]=0; sig[s]=1; order=[s]
        for v in order:
            for t_, e in rows[v]:
                if dist[t_] is None: dist[t_] = dist[v]+1; order.append(t_)
                if dist[t_] == dist[v]+1: sig[t_] += sig[v]
        delta = [Fraction(0)]*n
        for v in reversed(order):
            for t_, e in rows[v]:
                if dist[t_] == dist[v]+1: delta[v] += Fraction(sig[v], sig[t_]) * (1 + delta[t_])
            if v != s: bc[v] += delta[v]
    return [x / ((n-1)*(n-2)) for x in bc]
ex = exact_grid(g)
print("S6 max rel diff model vs exact", max(abs(float(e) - m)/max(1, abs(float(e))) for e, m in zip(ex, bg)), "max sigma digits", "time", time.time()-t)
dc = G(True, list(range(1000)), [(i, (i + 1) % 1000) for i in range(1000)])
show("S7 dcycle1000 betweenness unnormalized [0, 500]", [ref.betweenness_model(dc, None, False, False)[i] for i in (0, 500)])
