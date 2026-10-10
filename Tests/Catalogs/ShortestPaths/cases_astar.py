import sys, math
from ref import *
from cases import und, XG, XG2, XG3, XG4
def run(name, vertices, edges, s, t, h=lambda x: 0, order="written"):
    g = G(vertices, edges, order)
    outs = set()
    for tie in ("fifo", "lifo", "asc", "desc"):
        r = astar(g, s, t, h, tie)
        outs.add(None if r is None else (r[0], tuple(lab(g, r[1]))))
    print(f"--- A* {name} {s}->{t}:", outs if len(outs) > 1 else next(iter(outs)), "(tie-dependent)" if len(outs) > 1 else "")
print("\n================ A*")
run("NX XG h=0", [], XG, "s", "v")
run("NX XG2", [], XG2, 1, 3)
run("NX XG3 undirected", [], und(XG3), 0, 3)
run("NX XG4 undirected", [], und(XG4), 0, 2)
hv = {"n5": 36, "n2": 4, "n1": 0, "n0": 0}
run("NX directed3 inconsistent", [], [("n5","n1",11),("n5","n2",9),("n2","n1",1),("n1","n0",32)], "n5", "n0", lambda x: hv[x])
run("NX directed4", [], [("a","b",1),("a","c",1),("b","d",2),("c","d",1),("d","e",1)], "a", "e")
hi = {"s": 36, "y": 14, "x": 10, "u": 10, "v": 0}
run("NX XG inadmissible", [], XG, "s", "v", lambda x: hi[x])
ha = {"s": 36, "y": 4, "x": 0, "u": 0, "v": 0}
run("NX XG 'admissible' (h(s) large)", [], XG, "s", "v", lambda x: ha[x])
hm = {"a": 1.35, "b": 1.18, "c": 0.67, "d": 0}
run("NX multiple optimal paths (undirected)", [], und([("a","b",0.18),("a","c",0.68),("b","c",0.50),("c","d",0.67)]), "a", "d", lambda x: hm[x])
run("NX cycle7 undirected unit", [], und([(i,(i+1)%7,1) for i in range(7)]), 0, 3)
run("NX cycle7 undirected unit", [], und([(i,(i+1)%7,1) for i in range(7)]), 0, 4)
w1 = [(u,v,1) for u,v in [("s","u"),("s","x"),("u","v"),("u","x"),("v","y"),("x","u"),("x","w"),("w","v"),("x","y"),("y","s"),("y","v")]]
run("NX astar_w1 unit", [], w1, "s", "v")
run("NX XG unreachable", ["moon"], XG, "s", "moon")
# grid with Manhattan heuristic: 4x4 NetworkX grid relabeled 1..16 sorted
def gridedges(R, C, w=lambda a, b: 1):
    e = []
    for r in range(R):
        for c in range(C):
            if c + 1 < C: e.append(((r, c), (r, c + 1), w((r, c), (r, c + 1))))
            if r + 1 < R: e.append(((r, c), (r + 1, c), w((r, c), (r + 1, c))))
    return e
run("grid 4x4 unit, Manhattan to (3,3)", [(r,c) for r in range(4) for c in range(4)], und(gridedges(4,4)), (0,0), (3,3), lambda x: (3-x[0]) + (3-x[1]))
import random
rng = random.Random(5)
wts = {}
def rw(a, b):
    k = (a, b); wts.setdefault(k, rng.randint(1, 9)); return wts[k]
E = gridedges(6, 6, rw)
run("grid 6x6 weights 1..9 seed 5, Manhattan", [(r,c) for r in range(6) for c in range(6)], und(E), (0,0), (5,5), lambda x: (5-x[0]) + (5-x[1]))
g = G([(r,c) for r in range(6) for c in range(6)], und(E))
print("  grid 6x6 edges:", E)
