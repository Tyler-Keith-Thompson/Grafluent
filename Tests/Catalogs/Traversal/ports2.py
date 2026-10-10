from ref import *
from ports import S_of, sym
print("\n--- JGraphT AbstractGraphIteratorTest graph")
J=[('1','2'),('1','3'),('2','4'),('3','5'),('3','6'),('5','6'),('5','7'),('6','1'),('7','8'),('7','9'),('8','2'),('9','4')]
V=['1','2','3','4','5','6','7','8','9','orphan']
Sins={v:[] for v in V}
for u,w in J: Sins[u].append(w)
Srev={k:list(reversed(v)) for k,v in Sins.items()}
print("JGraphT-order (reverse insertion) DFS whole pre", preorder(dfs_events(Srev,V)), "post", postorder(dfs_events(Srev,V)))
print("insertion-order BFS whole", preorder(bfs_events(Sins,['1'])))
Sa={v:sorted(Sins[v], key=lambda x:(len(x),x)) for v in V}
ev=dfs_events(Sa,V); print("ascending DFS whole pre",preorder(ev),"post",postorder(ev),classes(ev)); print(fmt(ev))
b=bfs_events(Sa,['1']); print("ascending BFS from 1",preorder(b), "dist", bfs_dist(Sa,['1']))
ev=dfs_events(Sa,['orphan','7','9','4','8','2','3','6','1','5']); print("JGraphT multi-root order DFS pre", preorder(ev), "post", postorder(ev))
print("\n--- JGraphT bug 1169182")
B=[('A','B'),('B','C'),('C','J'),('C','D'),('C','E'),('C','F'),('C','G'),('D','H'),('E','H'),('F','I'),('G','I'),('H','J'),('I','C'),('J','K'),('K','L')]
VB=list('ABCDEFGHIJKL'); SB={v:[] for v in VB}
for u,w in B: SB[u].append(w)
print("JGraphT order (reverse insertion):", ''.join(preorder(dfs_events({k:list(reversed(v)) for k,v in SB.items()},VB))))
SBa={k:sorted(v) for k,v in SB.items()}
ev=dfs_events(SBa,VB); print("ascending:", ''.join(preorder(ev)), "post", ''.join(postorder(ev)), classes(ev))
print(" back edges", [(e[1],e[2]) for e in ev if e[0]=='B'])
print("\n--- JGraphT BFS searchTree")
Ja=[('a','b'),('b','c'),('b','z'),('b','d'),('d','e')]; SJ=S_of(sym(Ja))
b=bfs_events(SJ,['a']); print("depth", bfs_dist(SJ,['a']), "parent", parents_of(b))
print("\n--- JGraphT TopologicalOrderIterator")
T1=[('v0','v1'),('v0','v2'),('v1','v4'),('v2','v4'),('v3','v2'),('v3','v4'),('v4','v5')]
VT=['v0','v1','v2','v3','v4','v5']; ST=S_of(T1,VT)
print("kahn fifo", kahn_fifo(ST,VT), "lex", lex_topo(ST,VT), "gens", generations(ST,VT), "dfs", topo_dfs(ST,VT))
rec=[(0,1),(1,2),(0,2),(1,3),(2,3),(3,4),(4,5),(5,6),(6,7),(7,8),(6,8)]; SR=S_of(rec)
print("recipe kahn", kahn_fifo(SR,list(range(9))), "dfs", topo_dfs(SR,list(range(9))))
print("\n--- petgraph dfs_visit graph")
P=[(0,5),(0,2),(0,3),(0,1),(1,3),(2,3),(2,4),(4,0),(4,5)]; SP=S_of(P)
ev=dfs_events(SP,[0]); print(fmt(ev)); print("pre",preorder(ev),"post",postorder(ev),classes(ev))
# discovery/finish times CLRS 1-based
t=0; d={}; fi={}
for e in ev:
    if e[0]=='D': t+=1; d[e[1]]=t
    if e[0]=='X': t+=1; fi[e[1]]=t
print(" d", dict(sorted(d.items())), "f", dict(sorted(fi.items())))
# stop at tree edge into 4
out=[]
for e in ev:
    out.append(e)
    if e[0]=='T' and e[2]==4: break
print(" prefix until treeEdge(→4):", fmt(out))
evp=dfs_events(SP,[0],prune={2}); print(" prune 2:", fmt(evp))
print(" petgraph-order (reverse insertion) path", "neighbors(0) reversed insertion:", [5,2,3,1][::-1])
print("\n--- petgraph graph.rs dfs/bfs (H I J K Z)")
PH=[('H','I'),('H','J'),('I','J'),('I','K')]; VH=['H','I','J','K','Z']; SH=S_of(PH,VH); SHr=S_of([(b,a) for a,b in PH],VH)
for s,S_ in [('H',SH),('I',SH)]: print(s, "dfs count", len(preorder(dfs_events(S_,[s]))), "bfs order", preorder(bfs_events(S_,[s])))
print("reversed from H", preorder(dfs_events(SHr,['H'])), "reversed from K", preorder(dfs_events(SHr,['K'])))
print("\n--- petgraph dfs_order HIJK")
PO=[('H','I'),('H','J'),('H','K'),('I','K'),('K','I')]; SO=S_of(PO)
print(preorder(dfs_events(SO,['H'])), fmt(dfs_events(SO,['H'])))
print("\n--- petgraph toposort graph with disjoint part")
TT=F['petgraphDAG']['edges']+[('h','i'),('h','j'),('i','j')]; VT=sorted(set(sum(TT,()))); STT=S_of(TT)
print("dfs", topo_dfs(STT,VT), "lex", lex_topo(STT,VT), "gens", generations(STT,VT))
print("\n--- LEMON dfs_test")
L=[(0,1),(1,2),(2,3),(1,4),(4,2),(4,5),(5,0),(6,3)]; SL=S_of(L)
ev=dfs_events(SL,[0]); par=parents_of(ev); print(fmt(ev))
depth={0:0}
for (u,v) in tree_edges(ev): depth[v]=depth[u]+1
path=[5]
while path[-1]!=0: path.append(par[path[-1]])
print(" dfs path 0->5", path[::-1], "depth", depth)
print(" from 6 reaches", preorder(dfs_events(SL,[6])))
print(" bfs dist from 0", bfs_dist(SL,[0]))
print("\n--- igraph topological_sorting")
I=[(0,3),(0,4),(1,3),(2,4),(2,7),(3,5),(3,6),(3,7),(4,6)]; SI=S_of(I); VI=list(range(8))
print("kahn fifo OUT", kahn_fifo(SI,VI), "lex", lex_topo(SI,VI), "dfs", topo_dfs(SI,VI), "gens", generations(SI,VI))
SIr=S_of([(b,a) for a,b in I]); print("kahn fifo IN", kahn_fifo(SIr,VI))
SIc=S_of(I+[(5,0)]); print("with 5->0: kahn", kahn_fifo(SIc,VI), "cycle", first_back_cycle(SIc,VI))
print("\n--- igraph bfs_simple kary tree 20,2 OUT from 7")
K=[(i,c) for i in range(20) for c in (2*i+1,2*i+2) if c<20]; SK=S_of(K)
print(" order", preorder(bfs_events(SK,[7])), "layers", layers(SK,[7]), "dist", bfs_dist(SK,[7]))
print(" from 0 order", preorder(bfs_events(SK,[0])), "layer sizes", [len(l) for l in layers(SK,[0])])
