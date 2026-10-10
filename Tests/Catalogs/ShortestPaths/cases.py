import sys, math
import networkx as nx
from ref import *

def und(edges):  # an undirected edge list as the arcs of `graph.directed`: u->v then v->u per edge
    out = []
    for u, v, w in edges:
        out.append((u, v, w))
        if u != v: out.append((v, u, w))
        else: out.append((u, u, w))
    return out

def show_dij(name, vertices, edges, sources, order="written", cutoff=None):
    g = G(vertices, edges, order)
    dist, _, _ = dijkstra(g, sources, cutoff=cutoff)
    rule = determined_parents(g, sources, dist)
    ds = {g.label(i): dist[i] for i in range(g.n)}
    ps = {}
    for i, r in enumerate(rule):
        v = g.label(i)
        if r[0] == "root": ps[v] = "nil(root)"
        elif r[0] == "none": ps[v] = "nil(unreached)"
        elif r[0] == "exact": ps[v] = f"{g.label(r[1])} e{r[2]}"
        else: ps[v] = "any of " + str(sorted((g.label(u), k) for u, k in r[1]))
    # paths when determined
    print(f"--- {name} [{order}] sources={sources} cutoff={cutoff}")
    print("  dist:", ds)
    print("  parent:", ps)
    return g, dist, rule

def show_bf(name, vertices, edges, sources, order="written"):
    g = G(vertices, edges, order)
    r = bellman_ford(g, sources)
    print(f"--- BF {name} [{order}] sources={sources}")
    if r[0] == "tree":
        _, dist, par, pe, rounds = r
        print("  dist:", {g.label(i): dist[i] for i in range(g.n)})
        print("  parent:", {g.label(i): (None if par[i] is None else f"{g.label(par[i])} e{pe[i]}") for i in range(g.n)})
        print("  rounds:", rounds)
    else:
        print("  NEGATIVE CYCLE witness:", lab(g, r[1]), "weight", cycle_weight(g, r[1]))
    return g, r

XG = [("s","u",10),("s","x",5),("u","v",1),("u","x",2),("v","y",1),("x","u",3),("x","v",5),("x","y",2),("y","s",7),("y","v",6)]
show_dij("NetworkX XG", [], XG, ["s"])
show_dij("NetworkX XG cutoff 8", [], XG, ["s"], cutoff=8)
for s in ["u","v","x","y"]: show_dij("NetworkX XG", [], XG, [s])
MXG = XG + [("s","u",15)]
show_dij("NetworkX MXG (s->u 10 and 15)", [], MXG, ["s"])
XG2 = [(1,4,1),(4,5,1),(5,6,1),(6,3,1),(1,3,50),(1,2,100),(2,3,100)]
show_dij("XG2", [], XG2, [1])
XG3 = [(0,1,2),(1,2,12),(2,3,1),(3,4,5),(4,5,1),(5,0,10)]
show_dij("XG3 undirected", [], und(XG3), [0])
XG4 = [(0,1,2),(1,2,2),(2,3,1),(3,4,1),(4,5,1),(5,6,1),(6,7,1),(7,0,1)]
show_dij("XG4 undirected", [], und(XG4), [0])
show_dij("MXG4 undirected + 0-1 w3", [], und(XG4 + [(0,1,3)]), [0])
show_dij("MXG4 cutoff 2", [], und(XG4 + [(0,1,3)]), [0], cutoff=2)
GG = [(u,v,w) for (u,v,w) in XG if (u,v) != ("x","u")]
show_dij("XG undirected (u-x weight 2)", [], und(GG), ["s"])
# Boost dijkstra example A..E = 0..4
boost = [(0,2,1),(1,1,2),(1,3,1),(1,4,2),(2,1,7),(2,3,3),(3,4,1),(4,0,1),(4,1,1)]
show_dij("Boost dijkstra-example", range(5), boost, [0], "written")
show_dij("Boost dijkstra-example", range(5), boost, [0], "ascending")
# JGraphT testShortestPathTree V1..V5 = 1..5
jg = [(1,2,3.0),(2,4,1.0),(1,3,1.0),(3,2,1.0),(3,4,3.0)]
show_dij("JGraphT shortest path tree", [1,2,3,4,5], jg, [1])
# scipy directed_G
# numpy unused
dG = [[0,3,3,0,0],[0,0,0,2,4],[0,0,0,0,0],[1,0,0,0,0],[2,0,0,2,0]]
sc = [(i,j,dG[i][j]) for i in range(5) for j in range(5) if dG[i][j]]
for s in range(5): show_dij("scipy directed_G", range(5), sc, [s], "ascending")
uG = [[0,3,3,1,2],[3,0,0,2,4],[3,0,0,0,0],[1,2,0,0,2],[2,4,0,2,0]]
scu = [(i,j,uG[i][j]) for i in range(5) for j in range(i+1,5) if uG[i][j]]
for s in range(5): show_dij("scipy undirected_G via directed view (edges i<j ascending)", range(5), und(scu), [s])
for s in range(5): show_dij("scipy undirected limit 2", range(5), und(scu), [s], cutoff=2)
show_dij("NetworkX two sources (undirected)", [], und([(0,1,1),(1,2,1),(2,3,10),(3,4,1)]), [0,4])
show_dij("NetworkX 4-cycle undirected unit", [], und([(0,1,1),(1,2,1),(2,3,1),(3,0,1)]), [0])
show_dij("petgraph dijkstra doc unit", range(9), [(0,1,1),(1,2,1),(2,3,1),(3,0,1),(4,5,1),(1,4,1),(5,6,1),(6,7,1),(7,4,1)], [1])
show_dij("petgraph spfa_weighted", range(4), [(0,1,1),(0,2,4),(0,3,10),(1,2,2),(1,3,2),(2,3,2)], [0], "ascending")
show_dij("petgraph spfa_multiple_edges (MG)", range(4), [(0,1,10),(0,1,1),(0,2,4),(0,3,10),(1,2,2),(1,3,2),(2,3,2),(0,3,100),(2,3,20),(0,0,5)], [0])
