import networkx as nx
from collections import Counter
def sorted_dfs(G, s):
    seen, out = set(), []
    def go(u):
        seen.add(u); out.append(u)
        for w in sorted(set(G[u])):
            if w not in seen: go(w)
    go(s); return out
for name, g in [("petersen", nx.petersen_graph()), ("cube", nx.convert_node_labels_to_integers(nx.hypercube_graph(3), ordering="sorted")), ("house", nx.house_graph()), ("karate", nx.karate_club_graph())]:
    print(name, "sorted dfs preorder", sorted_dfs(g, 0))
# components
G = nx.Graph(); G.add_nodes_from(range(7)); G.add_edges_from([(0,1),(1,2),(3,4)])
print("components", sorted(sorted(c) for c in nx.connected_components(G)), "count", nx.number_connected_components(G))
# bridges with a parallel edge
M = nx.MultiGraph([(0,1),(1,2),(1,2)])
print("multigraph bridges", list(nx.bridges(M)))
print("simple bridges", list(nx.bridges(nx.Graph([(0,1),(1,2)]))))
# Eulerian with loops
for es in [[(0,0)], [(0,1),(1,2),(2,0),(0,0)], [(0,1),(1,2),(2,0),(0,1)]]:
    g = nx.MultiGraph(es); print("eulerian", es, nx.is_eulerian(g), dict(g.degree()))
# undirected DFS classification vs directed CLRS on the symmetric digraph
K4 = nx.complete_graph(4)
print("nx undirected dfs_labeled_edges K4", Counter(d for u,v,d in nx.dfs_labeled_edges(K4, 0) if u != v))
def clrs(D, s):
    color = {}; cls = Counter(); t = [0]; disc = {}
    def go(u):
        color[u] = 'g'; disc[u] = t[0]; t[0]+=1
        for w in sorted(D.successors(u)):
            if w not in color: cls['tree'] += 1; go(w)
            elif color[w] == 'g': cls['back'] += 1
            elif disc[w] > disc[u]: cls['forward'] += 1
            else: cls['cross'] += 1
        color[u] = 'b'
    go(s); return cls
print("CLRS on K4.to_directed()", clrs(K4.to_directed(), 0))
print("karate edges m", nx.karate_club_graph().number_of_edges())
# Sum of degrees, loops
L = nx.Graph([(0,0)]); print("single loop degree", dict(L.degree()), "m", L.number_of_edges(), "nbrs", list(L.neighbors(0)))
# K3 + loop (nx test_selfloops)
K3 = nx.complete_graph(3); K3.add_edge(0,0); print("K3+loop degree", dict(K3.degree()), "m", K3.number_of_edges(), "selfloops", nx.number_of_selfloops(K3))
# AsUndirected of directed reciprocal arcs: nx collapses
D = nx.DiGraph([(1,2),(2,1),(2,3),(3,1)]); U = D.to_undirected(); print("triangleWithReciprocal to_undirected m", U.number_of_edges(), dict(U.degree()))
print("MultiGraph(D) keeps both?", nx.MultiGraph(nx.MultiDiGraph(D)).number_of_edges())
D2 = nx.DiGraph([(5,3),(3,4),(3,2),(4,0),(4,1),(2,1),(1,0)]); U2 = D2.to_undirected()
print("house dag undirected degrees", dict(sorted(U2.degree())), "bfs from 5", dict(sorted(nx.single_source_shortest_path_length(U2,5).items())), "components", nx.number_connected_components(U2))
D3 = nx.DiGraph([(6,0),(0,3),(3,6),(8,6),(8,2),(2,5),(5,8),(7,5),(1,7),(7,4),(4,1)]); print("scc9 weak components", nx.number_weakly_connected_components(D3))
