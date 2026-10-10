from ref import *
bad = 0
for name, f in F.items():
    S = succ_sorted(f); V = sorted(vertex_set(f)); G = nxdg(f)
    for s in V[:3] + V[-2:]:
        ev = dfs_events(S, [s])
        assert tree_edges(ev) == list(nx.dfs_edges(G, s, sort_neighbors=sorted)), (name, s)
        assert preorder(ev) == list(nx.dfs_preorder_nodes(G, s, sort_neighbors=sorted)), (name,s)
        assert postorder(ev) == list(nx.dfs_postorder_nodes(G, s, sort_neighbors=sorted)), (name,s)
        nontree = [(u,v) for (u,v,d) in nx.dfs_labeled_edges(G, s, sort_neighbors=sorted) if d=='nontree']
        assert nontree == [(e[1],e[2]) for e in ev if e[0] in 'BFC'], (name,s)
        bev = bfs_events(S, [s])
        assert tree_edges(bev) == list(nx.bfs_edges(G, s, sort_neighbors=sorted)), (name,s)
        assert bfs_dist(S,[s]) == dict(nx.single_source_shortest_path_length(G, s)), (name,s)
        assert [sorted(l) for l in layers(S,[s])] == [sorted(l) for l in nx.bfs_layers(G, [s])]
        assert set(bfs_dist(S,[s])) - {s} == nx.descendants(G, s)
    ev = dfs_events(S, V)
    assert tree_edges(ev) == list(nx.dfs_edges(G, sort_neighbors=sorted)), name
    assert preorder(ev) == list(nx.dfs_preorder_nodes(G, sort_neighbors=sorted)), name
    acyclic = nx.is_directed_acyclic_graph(G)
    assert acyclic == (classes(ev)['B'] == 0), name
    if acyclic:
        assert lex_topo(S, V) == list(nx.lexicographical_topological_sort(G)), name
        assert generations(S, V) == [sorted(g) for g in nx.topological_generations(G)], name
        t = topo_dfs(S, V); pos = {v:i for i,v in enumerate(t)}
        assert all(pos[u] < pos[v] for u,v in G.edges()), name
    else:
        c = first_back_cycle(S, V)
        assert all(G.has_edge(c[i], c[(i+1)%len(c)]) for i in range(len(c))) and len(set(c))==len(c), name
print("all cross-checks passed for", len(F), "fixtures")
