import networkx as nx
def show(k, v): print(f"{k}: {v}")
# Self-loop conventions
G = nx.Graph([(0,0),(0,1),(1,2)])
show("Graph loop neighbors(0)", list(G.neighbors(0)))
show("Graph loop degree", dict(G.degree()))
show("Graph loop number_of_edges", G.number_of_edges())
show("Graph loop edges", list(G.edges()))
show("Graph loop edges(0)", list(G.edges(0)))
D = G.to_directed()
show("to_directed edges", sorted(D.edges()), )
show("to_directed out_degree", dict(D.out_degree()))
H = G.copy(); H.remove_node(0); show("remove 0 -> edges", list(H.edges())); show("remove 0 -> nodes", list(H.nodes()))
M = nx.MultiGraph([(0,1),(0,1),(0,0)])
show("MultiGraph neighbors(0)", list(M.neighbors(0))); show("MultiGraph degree", dict(M.degree())); show("MultiGraph m", M.number_of_edges())
show("MultiGraph edges(0)", list(M.edges(0)))
# petgraph undirected fixture: a b c d = 0 1 2 3
P = nx.MultiGraph([(0,1),(0,2),(2,0),(0,0),(1,2),(1,0),(0,3)])
show("petgraph multigraph degree", dict(P.degree())); show("m", P.number_of_edges())
show("petgraph nx neighbors(1)", list(P.neighbors(1)))
P.remove_node(0); show("after remove a: edges", list(P.edges())); show("nodes", list(P.nodes()))
# Classic graphs
for name, g in [("petersen", nx.petersen_graph()), ("cube", nx.hypercube_graph(3)), ("house", nx.house_graph()), ("karate", nx.karate_club_graph()), ("P4", nx.path_graph(4)), ("K4", nx.complete_graph(4)), ("C5", nx.cycle_graph(5))]:
    if name == "cube":
        g = nx.convert_node_labels_to_integers(g, ordering="sorted")
    print(f"== {name}: n={g.number_of_nodes()} m={g.number_of_edges()} degrees={dict(g.degree())}")
    print("   edges", sorted(tuple(sorted(e)) for e in g.edges()) if name != "karate" else "")
    print("   bfs dist from 0", dict(sorted(nx.single_source_shortest_path_length(g, 0).items())))
    print("   bfs layers from 0", [sorted(l) for l in nx.bfs_layers(g, 0)])
    print("   bipartite", nx.is_bipartite(g), "eulerian", nx.is_eulerian(g), "bridges", sorted(tuple(sorted(e)) for e in nx.bridges(g)), "artic", sorted(nx.articulation_points(g)))
    print("   dfs preorder sorted nbrs from 0", list(nx.dfs_preorder_nodes(nx.Graph(sorted((min(e),max(e)) for e in g.edges())), 0)) )
