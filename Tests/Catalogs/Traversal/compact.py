from ref import *
import io, contextlib
with contextlib.redirect_stdout(io.StringIO()):
    from ports import S_of, sym
    from ports5 import multi
def c(ev):
    o=[]
    for e in ev:
        q=lambda x: x if isinstance(x,int) else x
        if len(e)==2: o.append(f"{e[0]}{e[1]}")
        else: o.append(f"{e[0]}{e[1]}→{e[2]}")
    return ' '.join(o)
def fxS(n): f=F[n]; return succ_sorted(f), sorted(vertex_set(f))
cases = [
 ('BFS','directedPath3',[0]),('BFS','completeDirected3',[0]),('BFS','networkXFunctionGraph',[0]),('BFS','house',[5]),('BFS','scc9',[1]),
 ('BFS','petgraphEdgesDirected',[0]),('BFS','singleSelfLoop',[0]),('BFS','selfLoopsAndDuplicates',[1]),('BFS','neo4jDirected',[0]),('BFS','petgraphDAG',['a']),
 ('BFS','house',[3,4]),('BFS','boostWebGraph',[0]),('BFS','igraphReverseEdges',[0]),
 ('DFS','directedPath3',[0]),('DFS','completeDirected3',[0]),('DFS','networkXFunctionGraph',[0]),('DFS','house',[5]),('DFS','scc9',[1]),
 ('DFS','petgraphEdgesDirected',[0]),('DFS','singleSelfLoop',[0]),('DFS','triangleWithReciprocalEdge',[1]),('DFS','directedCycle4',[1]),
 ('DFS','neo4jDirected',[0]),('DFS','petgraphDAG',['a']),('DFS','networkXABCD',['A']),('DFS','cube',[0]),('DFS','boostWebGraph',[0]),('DFS','jgraphtMatrixCSV',[0]),
 ('DFS','petgraphCsr1',[0]),('DFS','igraphReverseEdges',[0]),('DFS','petgraphBellmanFord',[0]),('DFS','jgraphtSparseDirected',[0]),
 ('DFSW','house',None),('DFSW','boostExample',None),('DFSW','boostCsrUnsorted',None),('DFSW','scipyConstructor2',None),('DFSW','petgraphEdgesDirected',None),('DFSW','scc9',None),('DFSW','networkXABCD',None),('DFSW','petgraphCsr1',None),('DFSW','selfLoopsAndDuplicates',None),('DFSW','isolatedVertices',None),('DFSW','petgraphCsrFrom',None),('DFSW','petgraphBellmanFord',None),
 ('DFS','house',[3,0,5]),
]
for kind,n,src in cases:
    S,V=fxS(n)
    if kind=='BFS': print(f"{kind} {n} from {src}: {c(bfs_events(S,src))}")
    elif kind=='DFS': print(f"{kind} {n} from {src}: {c(dfs_events(S,src))}")
    else: print(f"{kind} {n}: {c(dfs_events(S,V))}")
print("MULTI")
for n in ['pathWithChord','selfLoopsAndDuplicates','jgraphtSparseDirected','networkXFunctionGraph']:
    S,V=multi(F[n]); print(n, "DFSW:", c(dfs_events(S,V)), "| BFS from", V[0], c(bfs_events(S,[V[0]])))
print("NXG", c(dfs_events(S_of(sym([(0,1),(1,2),(1,3),(2,4),(3,0),(0,4)])),[0])))
print("NXD", c(dfs_events(S_of(sym([(0,1),(2,3)])),[0,1,2,3])))
print("NXBFS", c(bfs_events(S_of(sym([(0,1),(1,2),(1,3),(2,4),(3,4)])),[0])))
print("C5", c(bfs_events(S_of([(i,(i+1)%5) for i in range(5)]+[(4,4)]),[0])))
print("C5plus", c(bfs_events(S_of([(i,(i+1)%5) for i in range(5)]+[(0,2),(1,5),(2,5)]),[0])))
print("K3ms", c(bfs_events(S_of(sym([(0,1),(0,2),(1,2)])),[0,1])))
P=[(0,5),(0,2),(0,3),(0,1),(1,3),(2,3),(2,4),(4,0),(4,5)]; SP=S_of(P)
print("PGV", c(dfs_events(SP,[0]))); print("PGVprune2", c(dfs_events(SP,[0],prune={2})))
print("PGVprune0", c(dfs_events(SP,[0],prune={0})))
print("PGVbfsprune2", "manual")
L=[(0,1),(1,2),(2,3),(1,4),(4,2),(4,5),(5,0),(6,3)]; print("LEMON", c(dfs_events(S_of(L),[0])))
T=S_of(sym([(i,i+1) for i in range(6)]+[(2,7),(7,8),(8,9),(9,10)]))
print("T5L1", c(dfs_events(T,[5],depth_limit=1))); print("T6L2", c(dfs_events(T,[6],depth_limit=2)))
print("T0L0", c(dfs_events(T,[0],depth_limit=0)))
DD=S_of(sym([(0,1),(2,3),(2,7),(7,8),(8,9),(9,10)])); print("DDW1", c(dfs_events(DD,sorted(DD),depth_limit=1)))
J={'1':['2','3'],'2':['4'],'3':['5','6'],'4':[],'5':['6','7'],'6':['1'],'7':['8','9'],'8':['2'],'9':['4'],'orphan':[]}
print("JGT", c(dfs_events(J,['1','2','3','4','5','6','7','8','9','orphan'])))
print("JGTbfs", c(bfs_events(J,['1'])))
