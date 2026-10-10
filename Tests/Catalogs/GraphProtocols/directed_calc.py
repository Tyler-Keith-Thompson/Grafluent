import networkx as nx
F = {}
F['house'] = ([], [(5,3),(3,4),(3,2),(4,0),(4,1),(2,1),(1,0)])
F['scc9'] = ([], [(6,0),(0,3),(3,6),(8,6),(8,2),(2,5),(5,8),(7,5),(1,7),(7,4),(4,1)])
F['networkXFunctionGraph'] = ([4], [(0,1),(0,2),(0,3),(1,1),(1,2),(1,0)])
F['boostExample'] = ([0], [(1,2),(1,5),(2,0),(2,2),(3,4),(4,3),(5,0)])
F['boost24'] = ([], [(1,2),(2,10),(2,5),(3,10),(3,0),(4,5),(4,0),(5,14),(6,3),(7,17),(7,11),(8,17),(8,1),(9,11),(9,1),(10,19),(10,15),(10,8),(11,19),(11,15),(11,4),(12,19),(12,8),(12,4),(13,15),(13,8),(13,4),(14,22),(14,12),(15,22),(15,6),(16,12),(16,6),(17,20),(18,9),(19,23),(19,18),(20,23),(20,13),(21,18),(21,13),(22,21),(23,16)])
F['petgraphEdgesDirected'] = ([], [(0,5),(0,2),(0,3),(0,1),(1,3),(2,3),(2,4),(4,0),(6,6)])
F['petgraphBellmanFord'] = ([], [(0,1),(0,2),(1,0),(1,1),(1,2),(1,3),(2,3),(4,5),(5,7),(6,7),(7,8)])
F['jgraphtSparseDirected'] = ([], [(0,1),(1,0),(1,4),(1,5),(1,6),(2,4),(2,4),(2,4),(3,4),(4,5),(5,6),(7,6),(7,7)])
F['pathWithChord'] = ([], [(0,1),(1,2),(2,3),(3,4),(4,5),(1,3),(1,3)])
F['neo4jDirected'] = ([], [(0,1),(0,2),(1,2),(1,3),(2,4),(3,4)])
F['igraphReverseEdges'] = ([], [(0,1),(1,2),(2,3),(3,1),(1,4)])
F['petgraphDAG'] = ([], [("a","b"),("a","d"),("d","b"),("b","c"),("b","e"),("c","e"),("d","e"),("d","f"),("f","e"),("f","g"),("e","g")])
F['networkXABCD'] = (["G","J","K"], [("A","B"),("A","C"),("B","D"),("B","C"),("C","D")])
F['directedCycle4'] = ([], [(1,2),(2,3),(3,4),(4,1)])
F['petgraphCsrFrom'] = ([3], [(0,1),(0,2),(1,0),(1,1),(2,2),(2,4)])
F['boostCsrUnsorted'] = ([], [(5,0),(3,2),(4,1),(4,0),(0,2),(5,2)])
F['scipyConstructor2'] = ([0,1,2,5], [(3,4)])
def srt(x):
    return sorted(x, key=lambda v: (str(type(v)), v))
for name,(vs,es) in F.items():
    G = nx.DiGraph(); G.add_nodes_from(vs); G.add_edges_from(es)
    M = nx.MultiDiGraph(); M.add_nodes_from(vs); M.add_edges_from(es)
    src = srt(G.nodes)[0]
    print("==", name, "n", G.number_of_nodes(), "m", G.number_of_edges(), "multi m", M.number_of_edges())
    print("  source", src, "descendants", srt(nx.descendants(G, src)))
    d = nx.single_source_shortest_path_length(G, src)
    print("  bfs dist", {k: d[k] for k in srt(d)})
    print("  isDAG", nx.is_directed_acyclic_graph(G), "selfloops", nx.number_of_selfloops(G))
    if nx.is_directed_acyclic_graph(G):
        print("  generations", [srt(g) for g in nx.topological_generations(G)])
        print("  multi generations", [srt(g) for g in nx.topological_generations(M)])
        print("  lexico topo", list(nx.lexicographical_topological_sort(G)))
    else:
        try:
            c = nx.find_cycle(G, src)
        except nx.NetworkXNoCycle:
            c = None
    sccs = srt([srt(c) for c in nx.strongly_connected_components(G)])
    print("  SCCs", sccs, "count", len(sccs))
    print("  weak comps", len(list(nx.weakly_connected_components(G))))
    # BFS order with ascending successors
    order=[src]; seen={src}; q=[src]
    while q:
        u=q.pop(0)
        for v in srt(G.successors(u)):
            if v not in seen: seen.add(v); order.append(v); q.append(v)
    print("  bfs order ascending", order)
    order=[]; seen=set()
    def dfs(u):
        seen.add(u); order.append(u)
        for v in srt(G.successors(u)):
            if v not in seen: dfs(v)
    dfs(src); print("  dfs preorder ascending", order)
    print("  dfs preorder nx", list(nx.dfs_preorder_nodes(G, src, sort_neighbors=srt)))
    # reverse reachability (ancestors) of max vertex
    t = srt(G.nodes)[-1]
    print("  ancestors of", t, srt(nx.ancestors(G, t)))
print("\n#### chosen sources")
for name, s in [('house',5),('boost24',7),('boost24',1),('boostExample',1),('scc9',1),('jgraphtSparseDirected',2),('petgraphEdgesDirected',6),('networkXFunctionGraph',4)]:
    vs,es = F[name]; G = nx.DiGraph(); G.add_nodes_from(vs); G.add_edges_from(es)
    d = nx.single_source_shortest_path_length(G, s)
    print(name, s, "desc", srt(nx.descendants(G,s)), "dist", {k:d[k] for k in srt(d)})
for name in ['jgraphtSparseDirected','pathWithChord']:
    vs,es = F[name]; M = nx.MultiDiGraph(); M.add_nodes_from(vs); M.add_edges_from(es)
    print(name, "multi out", dict(M.out_degree()), "in", dict(M.in_degree()), "succ lens", {v: len(list(M.successors(v))) for v in M})
