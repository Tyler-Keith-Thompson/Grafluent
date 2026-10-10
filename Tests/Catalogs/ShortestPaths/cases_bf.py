import sys
import networkx as nx
from ref import *
from cases import und, show_bf, XG
print("\n================ BELLMAN-FORD")
clrs = [("u","y",-4),("u","x",8),("u","v",5),("v","u",-2),("x","y",9),("x","v",-3),("y","v",7),("y","z",2),("z","u",6),("z","x",7)]
show_bf("Boost bellman-example (CLRS 24.4)", ["u","v","x","y","z"], clrs, ["z"])
c5 = [(i,(i+1)%5,1) for i in range(5)]
show_bf("NX negative_weight cycle5 1->2=-3", range(5), [(u,v,(-3 if (u,v)==(1,2) else w)) for u,v,w in c5], [0])
for i in range(5): show_bf("NX negative_cycle cycle5 1->2=-7", range(5), [(u,v,(-7 if (u,v)==(1,2) else w)) for u,v,w in c5], [i])
for i in range(5): show_bf("NX negative_cycle undirected cycle5 1-2=-3", range(5), und([(u,v,(-3 if (u,v)==(1,2) else w)) for u,v,w in c5]), [i])
show_bf("NX self-loop -1", [1], [(1,1,-1)], [1])
show_bf("NX zero cycle 2->3=-4", range(5), [(u,v,(-4 if (u,v)==(2,3) else w)) for u,v,w in c5], [1])
show_bf("NX zero cycle 2->3=-4.0001", range(5), [(u,v,(-4.0001 if (u,v)==(2,3) else w)) for u,v,w in c5], [1])
longer = c5 + [(3,5,1),(5,6,1),(6,7,1),(7,8,1),(8,9,1),(9,3,1)]
longer = [(u,v,(-30 if (u,v)==(1,2) else w)) for u,v,w in longer]
show_bf("NX find_negative_cycle_longer_cycle from 1", range(10), longer, [1])
show_bf("NX find_negative_cycle_longer_cycle from 7", range(10), longer, [7])
show_bf("NX single edge undirected 0-1=-1 from 1", [], und([(0,1,-1)]), [1])
show_bf("NX find_negative_cycle docstring", [], [(0,1,2),(1,2,2),(2,0,1),(1,4,2),(4,0,-5)], [0])
h = [(0,1,-1),(1,2,-1),(2,3,-1),(3,0,3)]
show_bf("NX heuristic zero cycle", range(4), h, [0])
show_bf("NX heuristic + 2->0 1.999", range(4), h + [(2,0,1.999)], [0])
show_bf("NX heuristic + 2->0 2", range(4), h + [(2,0,2)], [0])
show_bf("NX negative_edge_cycle whole graph (all sources)", list(range(5))+[8,9], c5 + [(8,9,-7),(9,8,3)], list(range(5))+[8,9])
show_bf("NX negative_edge_cycle cycle5 only (all sources)", range(5), c5, list(range(5)))
show_bf("petgraph doc", range(6), [(0,1,2.0),(0,3,4.0),(1,2,1.0),(1,5,7.0),(2,4,5.0),(4,5,1.0),(3,4,1.0)], [0])
show_bf("petgraph doc undirected neg", range(6), und([(0,1,-2.0),(0,3,-4.0),(1,2,-1.0),(1,5,-25.0),(2,4,-5.0),(4,5,-25.0),(3,4,-1.0)]), [0])
pcsr = [(0,1,0.5),(0,2,2.),(1,0,1.),(1,1,1.),(1,2,1.),(1,3,1.),(2,3,3.),(4,5,1.),(5,7,2.),(6,7,1.),(7,8,3.)]
show_bf("petgraph csr test_bellman_ford", range(9), pcsr, [0], "ascending")
show_bf("petgraph find_neg_cycle1", range(4), [(0,1,0.5),(0,2,2.),(1,0,1.),(1,1,-1.),(1,2,1.),(1,3,1.),(2,3,3.)], [0], "ascending")
show_bf("petgraph find_negative_cycle doc", range(4), [(0,1,1.),(0,2,1.),(0,3,1.),(1,3,1.),(2,1,1.),(3,2,-3.)], [0], "ascending")
wiki = [("w","z",2),("y","w",4),("x","w",6),("x","y",3),("z","x",-7),("y","z",5),("z","y",-3),("s","w",0.0),("s","y",0.0),("s","x",0.0),("s","z",0.0)]
show_bf("JGraphT wikipedia", ["w","y","x","z","s"], wiki, ["s"])
wiki2 = [(u,v,(3 if (u,v)==("y","z") else w)) for u,v,w in wiki]
show_bf("JGraphT negative cycle actual", ["w","y","x","z","s"], wiki2, ["s"])
jgu = [("w","y",1),("y","x",1),("y","x",-1)]
show_bf("JGraphT negative undirected edge (parallel y-x 1 and -1) from w", ["w","y","x"], und(jgu), ["w"])
jgnc = [(str(i),str(i+1),1) for i in range(1,9)] + [("7","x",-3),("x","4",-3)]
show_bf("JGraphT testNegativeCycle", [str(i) for i in range(1,10)]+["x"], jgnc, ["1"])
jgnr = [("1","2",1),("2","3",1),("3","4",1),("5","4",1),("5","6",-1),("6","7",-1),("7","5",-1)]
show_bf("JGraphT unreachable negative cycle", ["1","2","3","4","5","6","7"], jgnr, ["1"])
V = ["V1","V2","V3","V4","V5"]
jb = [("V1","V2",2),("V1","V3",3),("V2","V4",5),("V3","V4",20),("V4","V5",5),("V1","V5",100)]
show_bf("JGraphT testUndirected from V3", V, und(jb), ["V3"])
show_bf("JGraphT withNegativeEdges (directed, negated)", V, [(u,v,-w) for u,v,w in jb], ["V1"])
show_bf("Boost bellman-test undirected B-A 11 from A (A,B,Z=0,1,2)", range(3), und([(1,0,11)]), [0])
show_bf("JGraphT maxHops graph 1->2->3->4->1(-5)", ["1","2","3","4"], [("1","2",1),("2","3",1),("3","4",1),("4","1",-5)], ["1"])
