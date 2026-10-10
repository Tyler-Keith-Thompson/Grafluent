import networkx as nx
from collections import Counter
K=[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
assert sorted(tuple(sorted(e)) for e in nx.karate_club_graph().edges()) == K
F = {
 'singleSelfLoop': ([0],[(0,0)]),
 'k3': ([],[(0,1),(0,2),(1,2)]),
 'k3WithLoop': ([],[(0,1),(0,2),(1,2),(0,0)]),
 'loopAndPath': ([],[(0,0),(0,1),(1,2)]),
 'petgraph': ([],[(0,1),(0,2),(2,0),(0,0),(1,2),(1,0),(0,3)]),
 'components7': (list(range(7)),[(0,1),(1,2),(3,4)]),
 'path4': ([],[(0,1),(1,2),(2,3)]),
 'cycle5': ([],[(0,1),(1,2),(2,3),(3,4),(0,4)]),
 'k4': ([],[(a,b) for a in range(4) for b in range(a+1,4)]),
 'house': ([],[(0,1),(0,2),(1,3),(2,3),(2,4),(3,4)]),
 'petersen': ([],[(0,1),(0,4),(0,5),(1,2),(1,6),(2,3),(2,7),(3,4),(3,8),(4,9),(5,7),(5,8),(6,8),(6,9),(7,9)]),
 'cube': ([],[(0,1),(0,2),(0,4),(1,3),(1,5),(2,3),(2,6),(3,7),(4,5),(4,6),(5,7),(6,7)]),
 'karate': ([],K),
 'parallelPath': ([],[(0,1),(1,2),(1,2)]),
}
assert sorted(tuple(sorted(e)) for e in nx.petersen_graph().edges()) == sorted(F['petersen'][1])
assert sorted(tuple(sorted(e)) for e in nx.house_graph().edges()) == sorted(F['house'][1])
for name,(vs,es) in F.items():
    g=nx.Graph(); g.add_nodes_from(vs); g.add_edges_from(es)
    m=nx.MultiGraph(); m.add_nodes_from(vs); m.add_edges_from(es)
    print(name, 'simple n/m', g.number_of_nodes(), g.number_of_edges(), dict(sorted(g.degree())), '| multi m', m.number_of_edges(), dict(sorted(m.degree())))
def sorted_dfs(G, s):
    seen, out = set(), []
    def go(u):
        seen.add(u); out.append(u)
        for w in sorted(set(G[u])):
            if w not in seen: go(w)
    go(s); return out
for name in ['petersen','cube','house','karate','cycle5','path4','k4']:
    g=nx.Graph(F[name][1])
    print(name,'dist',dict(sorted(nx.single_source_shortest_path_length(g,0).items())))
    print(name,'layers',[sorted(l) for l in nx.bfs_layers(g,0)])
    print(name,'dfs',sorted_dfs(g,0))
    print(name,'bridges',sorted(tuple(sorted(e)) for e in nx.bridges(g)),'bip',nx.is_bipartite(g),'euler',nx.is_eulerian(g),'cc',nx.number_connected_components(g))
g=nx.Graph(); g.add_nodes_from(range(7)); g.add_edges_from(F['components7'][1]); print('comp7', sorted(sorted(c) for c in nx.connected_components(g)))
print('parallelPath bridges', list(nx.bridges(nx.MultiGraph(F['parallelPath'][1]))))
for es in [[(0,0)], F['k3WithLoop'][1], [(0,1),(1,2),(2,0),(0,1)]]:
    mg=nx.MultiGraph(es); print('eulerian',es,nx.is_eulerian(mg))
print('loop bipartite', nx.is_bipartite(nx.Graph([(0,0)])))
# directed fixtures
house=[(5,3),(3,4),(3,2),(4,0),(4,1),(2,1),(1,0)]
U=nx.DiGraph(house).to_undirected(); print('dhouse undirected deg',dict(sorted(U.degree())),'bfs5',dict(sorted(nx.single_source_shortest_path_length(U,5).items())), nx.number_connected_components(U), sorted(tuple(sorted(e)) for e in U.edges()), 'nbr2', sorted(U[2]))
tri=[(1,2),(2,1),(2,3),(3,1)]
print('tri multi deg', dict(sorted(nx.MultiGraph(tri).degree())), 'simple', dict(sorted(nx.DiGraph(tri).to_undirected().degree())), nx.DiGraph(tri).to_undirected().number_of_edges())
sl=[(1,2),(2,3),(2,3),(2,4),(4,4),(5,5),(5,2),(5,5)]
D=nx.DiGraph(sl); print('selfloops digraph m',D.number_of_edges(),'deg',dict(sorted(D.degree())))
print('loopAndPath to_directed', sorted(nx.Graph(F['loopAndPath'][1]).to_directed().edges()))
K4=nx.complete_graph(4); print('nx undirected dfs K4', Counter(d for u,v,d in nx.dfs_labeled_edges(K4,0) if u!=v))
# house directed as undirected: neighbors of 2 through views
print('UAL(house).directed as AL edges', 2*6)
