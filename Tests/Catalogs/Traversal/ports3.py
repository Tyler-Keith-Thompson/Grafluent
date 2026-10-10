from ref import *
from ports import S_of, sym
import itertools
class Lazy(dict):
    def __init__(s, fn): s.fn=fn
    def __missing__(s,k): v=list(s.fn(k)); s[k]=v; return v
print("--- pathfinding dfs_reach")
print(preorder(dfs_events(Lazy(lambda n:[x for x in (n+1,n+5) if x<=10]),[0])))
print(preorder(dfs_events(Lazy(lambda n:[x for x in (n+2,n+5) if x<=10]),[0])))
print("bfs_reach same:", preorder(bfs_events(Lazy(lambda n:[x for x in (n+2,n+5) if x<=10]),[0])))
print("--- pathfinding topological_sort doc example roots [5,1]")
succ=Lazy(lambda n: [n+1,n+2] if n<=7 else ([9] if n==8 else []))
ev=dfs_events(succ,[5,1]); print("dfs reverse postorder", list(reversed(postorder(ev))))
succ2=Lazy(lambda n: [n+1,n+2,7] if n<=6 else ([8,9] if n==7 else ([7,9] if n==8 else [7])))
print("cycle?", classes(dfs_events(succ2,[5,1])), "witness", first_back_cycle(succ2,[5,1]))
print("--- pathfinding tsig")
for name,succs in [('diamond',[[1,2],[3],[3],[]]),('multi',[[1,5],[2],[3],[],[5],[3]]),('cycle3',[[1],[2],[0]]),('chain_cycle',[[1],[2],[3],[2,4],[]]),('selfedge',[[1,2],[3],[3],[3]]),('noedges',[[],[],[]])]:
    S={i:s for i,s in enumerate(succs)}; print(name, generations(S,list(S)))
print("--- pathfinding bfs multi-start a..e")
S={'a':['b'],'b':['c'],'c':['d'],'d':['e'],'e':[]}
print("bfs a->e via dist", bfs_dist(S,['a'])['e'], "from [a,b] first reaching {d,e}:", bfs_dist(S,['a','b']))
print("--- divisors topo (1..999) sample check skipped")
print("--- NX dag tests")
def show(edges, verts=None):
    S=S_of(edges, verts or ()); V=sorted(S)
    return dict(dfs=topo_dfs(S,V), kahn=kahn_fifo(S,V), lex=lex_topo(S,V), gens=generations(S,V), cyc=first_back_cycle(S,V))
print("ts1", show([(1,2),(1,3),(2,3)]))
print("ts1+32", show([(1,2),(1,3),(2,3),(3,2)]))
print("ts1-23", show([(1,3),(3,2)]))
print("ts2", show([(1,2),(2,3),(3,4),(4,5),(5,1),(11,12),(12,13),(13,14),(14,15)]))
print("ts2-12", show([(2,3),(3,4),(4,5),(5,1),(11,12),(12,13),(13,14),(14,15)]))
ts3=[(1,i) for i in range(2,5)]+[(2,i) for i in range(5,9)]+[(6,i) for i in range(9,12)]+[(4,i) for i in range(12,15)]
print("ts3", show(ts3)); print("ts3+14->1", show(ts3+[(14,1)]))
print("lex", lex_topo(S_of([(1,2),(2,3),(1,4),(1,5),(2,6)]),[1,2,3,4,5,6]), lex_topo(S_of([(1,2),(2,3),(1,4),(1,5),(2,6)]),[1,2,3,4,5,6],key=lambda x:-x))
g=[(2,1),(3,1),(4,2),(5,2),(7,3),(6,5),(7,5)]
print("gens", generations(S_of(g),sorted(S_of(g))))
print("gens cycle", show([(2,1),(3,1),(1,2)]))
def all_topo(S,V):
    out=[]
    for p in itertools.permutations(V):
        pos={v:i for i,v in enumerate(p)}
        if all(pos[u]<pos[v] for u in S for v in S[u]): out.append(list(p))
    return out
for E_ in [[(1,2),(2,3),(3,4),(4,5)],[(1,3),(2,1),(2,4),(4,3),(4,5)]]:
    S=S_of(E_); print("all topo", all_topo(S,sorted(S)))
A=[(1,2),(1,3),(4,2),(4,3),(4,5),(2,6),(5,6)]; SA=S_of(A); SAr=S_of([(b,a) for a,b in A])
for v in (6,3,1): print("ancestors",v, sorted(set(bfs_dist(SAr,[v]))-{v}))
for v in (1,4,3): print("descendants",v, sorted(set(bfs_dist(SA,[v]))-{v}))
print("--- all topological sorts counts on fixtures")
for nm in ['house','neo4jDirected','boostCsrUnsorted','scipyConstructor2','petgraphDAG','networkXABCD','directedPath10']:
    f=F[nm]; S=succ_sorted(f); G=nxdg(f); print(nm, sum(1 for _ in nx.all_topological_sorts(G)))
