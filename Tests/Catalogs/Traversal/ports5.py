from ref import *
def multi(f):
    V=[]; 
    for v in list(f['listed'])+[x for e in f['edges'] for x in e]:
        if v not in V: V.append(v)
    S={v:[] for v in V}
    for u,v in f['edges']: S[u].append(v)
    return S,V
for nm in ['pathWithChord','selfLoopsAndDuplicates','jgraphtSparseDirected','networkXFunctionGraph']:
    S,V=multi(F[nm]); print("==",nm,"Multigraph vertices",V,"succ",S)
    ev=dfs_events(S,V); print(" DFS whole:",fmt(ev)); print(" classes",classes(ev))
    b=bfs_events(S,[V[0]]); print(" BFS from",V[0],":",fmt(b))
    print(" kahn(multi indegree)", kahn_fifo(S,V), "gens", generations(S,V))
# two-vertex multigraph cases
for nm,E_ in [('double 0->1',[(0,1),(0,1)]),('double loop',[(0,0),(0,0)]),('antiparallel double',[(0,1),(0,1),(1,0)])]:
    S={0:[],1:[]}
    for u,v in E_: S[u].append(v)
    print(nm, fmt(dfs_events(S,[0,1])), "|", fmt(bfs_events(S,[0])), "| kahn", kahn_fifo(S,[0,1]))
print("--- real world")
for nm in ['gap4','graph500Scale8','ligraRMat']:
    f=F[nm]; S=succ_sorted(f); V=sorted(vertex_set(f)); G=nxdg(f)
    ev=dfs_events(S,V); c=classes(ev)
    s=V[0]
    # choose a source with largest reach
    d0=bfs_dist(S,[0]); L=layers(S,[0])
    evs=dfs_events(S,[0])
    print(nm, "n",len(V),"m",G.number_of_edges(),"whole DFS classes",c,"sum",sum(c.values()),"roots",len(V)-c['T'])
    print("  from 0: reach",len(d0),"ecc",max(d0.values()),"layer sizes",[len(l) for l in L],"dfs from 0 classes",classes(evs))
    print("  dfs from 0 pre[:12]",preorder(evs)[:12],"post[:12]",postorder(evs)[:12])
    print("  bfs from 0 order[:12]",preorder(bfs_events(S,[0]))[:12])
    print("  acyclic",nx.is_directed_acyclic_graph(G),"selfloops",nx.number_of_selfloops(G),"SCC count",nx.number_strongly_connected_components(G),"largest SCC",max(len(c) for c in nx.strongly_connected_components(G)))
    print("  cycle witness",first_back_cycle(S,V))
    print("  sum of BFS distances from 0", sum(d0.values()), "max outdeg vertex", max(V,key=lambda v:(len(S[v]),-v)), len(S[max(V,key=lambda v:(len(S[v]),-v))]))
    cond=nx.condensation(G); print("  condensation nodes",cond.number_of_nodes(),"generations",len(list(nx.topological_generations(cond))))
