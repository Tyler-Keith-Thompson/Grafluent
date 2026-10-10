from ref import *
small = [k for k in F if k not in ('gap4','graph500Scale8','ligraRMat','completeDirected10')]
for name in small:
    f = F[name]; S = succ_sorted(f); V = sorted(vertex_set(f))
    if not V: continue
    print("=====", name, "V=", V)
    print(" succ:", {k:S[k] for k in V})
    ev = dfs_events(S, V)
    print(" DFS whole pre:", preorder(ev), "post:", postorder(ev), "classes:", classes(ev))
    print(" DFS whole tree:", tree_edges(ev))
    print(" DFS whole nontree:", [(e[0],e[1],e[2]) for e in ev if e[0] in 'BFC'])
    s = V[0]
    if name == 'house': s = 5
    if name == 'boost24': s = 7
    if name == 'scc9': s = 1
    evs = dfs_events(S, [s]); b = bfs_events(S, [s])
    print(f" from {s!r}: DFS pre {preorder(evs)} post {postorder(evs)} classes {classes(evs)}")
    print(f"   BFS order {preorder(b)} layers {layers(S,[s])} parents {dict(sorted(parents_of(b).items()))}")
    print(f"   DFS parents {dict(sorted(parents_of(evs).items()))}")
    if len(evs) <= 40: print("   DFS transcript:", fmt(evs))
    if len(b) <= 40: print("   BFS transcript:", fmt(b))
    G = nxdg(f)
    if nx.is_directed_acyclic_graph(G):
        print(" topo dfs:", topo_dfs(S, V), " kahn fifo:", kahn_fifo(S, V), " lex:", lex_topo(S,V), " gens:", generations(S,V))
        print(" nx.topological_sort:", list(nx.topological_sort(G)))
    else:
        print(" cycle witness (DFS whole):", first_back_cycle(S, V), " kahn partial:", kahn_fifo(S,V), " gens partial:", generations(S,V))
        print(" nx.find_cycle:", nx.find_cycle(G, source=V))
