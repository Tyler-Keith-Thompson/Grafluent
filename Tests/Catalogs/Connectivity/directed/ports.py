"""Graphs ported from NetworkX, petgraph, JGraphT, Boost and LEMON tests: values in ascending order
(an AdjacencyMatrix/CSR built on the listed vertices, or a Multigraph whose edges are written in
ascending order with the listed vertices first)."""
import sys
sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
import networkx as nx
import ref

def asc(edges, vertices=()):
    f = dict(edges=list(edges), listed=list(vertices))
    return ref.ascending(f)

def show(title, edges, vertices=()):
    V, S = asc(edges, vertices)
    c, st = ref.tarjan(V, S)
    G = nx.DiGraph(); G.add_nodes_from(V); G.add_edges_from((u, w) for u in V for w in S[u])
    assert [set(x) for x in c] == list(nx.strongly_connected_components(G))
    print(f'{title}: V={V}')
    print(f'   scc={c}  (count {len(c)}) label={[ref.labels(c)[v] for v in V]}')
    print(f'   cond={ref.condensation(V, S, c)} attracting={ref.attracting(V, S, c)} weak={ref.weak(V, S)}')
    print(f'   strongly={len(c)==1} weakly={len(ref.weak(V,S))==1}')
    return V, S, c

print('--- NetworkX test_strongly_connected')
g1 = [(1,2),(2,3),(2,8),(3,4),(3,7),(4,5),(5,3),(5,6),(7,4),(7,6),(8,1),(8,7)]
show('nx gc0', g1)
show('nx gc1', [(1,2),(1,3),(1,4),(4,2),(3,4),(2,3)])
show('nx gc2', [(1,2),(2,3),(3,2),(2,1)])
show('nx gc3 eppstein', [(0,1),(1,2),(1,3),(2,4),(2,5),(3,4),(3,5),(4,6)], range(7))
show('nx gc4 eppstein', [(0,1),(1,2),(1,3),(1,4),(2,0),(2,3),(3,4),(4,3)])
cs = [(1,2),(2,3),(2,11),(2,12),(3,4),(4,3),(4,5),(5,6),(6,5),(6,7),(7,8),(7,9),(7,10),(8,9),(9,7),(10,6),(11,2),(11,4),(11,6),(12,6),(12,11)]
show('nx contract_scc1', cs)
show('nx contract isolate', [(1,2),(2,1)])
show('nx contract edge', [(1,2),(2,1),(2,3),(3,4),(4,3)])
show('nx early exit', [(0,1),(1,2),(1,5),(2,3),(3,1),(3,4),(4,0),(5,2)])
show('nx doc number_scc', [(0,1),(1,2),(2,0),(2,3),(4,5),(3,4),(5,6),(6,3),(6,7)])
show('nx doc is_strongly', [(0,1),(1,2),(2,3),(3,0),(2,4),(4,2)])
show('nx doc is_strongly minus 2-3', [(0,1),(1,2),(3,0),(2,4),(4,2)])
show('nx doc cycle4 + cycle 10,11,12', [(0,1),(1,2),(2,3),(3,0),(10,11),(11,12),(12,10)])
show('nx path5 disjoint union', [(0,1),(1,2),(2,3),(3,4),(5,6),(6,7),(7,8),(8,9)])
bar = [(u,v) for u in range(4) for v in range(4) if u!=v] + [(u,v) for u in range(4,8) for v in range(4,8) if u!=v]
show('nx barbell(4,0) minus 3-4 (both dirs)', bar)

print('--- NetworkX attracting')
show('nx att G1', [(5,11),(11,2),(11,9),(11,10),(7,11),(7,8),(8,9),(3,8),(3,10)])
show('nx att G2', [(0,1),(0,2),(1,1),(1,2),(2,1)])
show('nx att G3', [(0,1),(1,2),(2,1),(0,3),(3,4),(4,3)])

print('--- petgraph')
show('pg scc acyclic #14', [(3,2),(3,1),(2,0),(1,0)], range(4))
show('pg kosaraju bug PR60', [(0,0),(1,0),(2,0),(2,1),(2,2)], range(4))
show('pg condensation', [(6,0),(0,3),(3,6),(8,6),(8,2),(2,3),(2,5),(5,8),(7,5),(1,7),(7,4),(4,1)])
show('pg condensation doc a..h', [(0,1),(1,2),(2,3),(3,0),(1,4),(4,5),(5,6),(6,7),(7,4)])
show('pg tarjan doc A..E', [(0,1),(1,2),(2,0),(1,3),(3,4)])
show('pg connected_comp doc', [(6,0),(0,3),(3,6),(8,6),(8,2),(2,5),(5,8),(7,5),(1,7),(7,4)], range(9))
show('rustworkx doc', [(0,1),(1,2),(2,0),(3,4)])

print('--- JGraphT (v1..v11 as 1..11)')
show('jgt 1', [(1,2),(2,1),(3,4)], range(1,5))
show('jgt 2', [(1,2),(2,1),(4,3),(3,2)], range(1,5))
show('jgt 3', [(1,2),(2,3),(3,1),(1,4),(2,4),(3,4)], range(1,5))
show('jgt 4 ring3', [(0,1),(1,2),(2,0)])
show('jgt 5 gabow', [(1,2),(1,3),(2,3),(2,4),(4,3),(4,5),(5,2),(5,6),(6,3),(6,4)], range(1,7))
show('jgt 6 wikipedia', [(1,5),(2,1),(3,2),(3,4),(4,3),(5,2),(6,2),(6,5),(6,7),(7,3),(7,6),(8,4),(8,7)], range(1,9))
show('jgt 7', [(1,2),(2,3),(3,4),(3,5),(4,1),(5,3)], range(1,6))
show('jgt 8', [(1,2),(1,4),(2,3),(2,5),(3,1),(3,7),(4,3),(5,6),(5,7),(6,7),(6,8),(6,9),(6,10),(7,5),(8,10),(9,10),(10,9)], range(1,12))
show('jgt condensation', [(1,2),(2,1),(3,4),(5,4)], range(1,6))
show('jgt condensation2', [(1,2),(2,1),(3,4),(4,3),(1,3),(2,4)], range(1,5))

print('--- weak (NetworkX test_weakly_connected uses the same five graphs)')
