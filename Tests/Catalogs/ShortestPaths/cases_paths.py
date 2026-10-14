"""Values for section N of cases.md (SP-160 – SP-191): k shortest simple paths, all shortest paths,
bidirectional Dijkstra, Johnson and all-pairs Dijkstra, from NetworkX, checked against brute force.

uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/ShortestPaths/cases_paths.py > Tests/Catalogs/ShortestPaths/cases_paths.out
"""
import itertools
import networkx as nx


def digraph(edges, directed=True, nodes=()):
    G = nx.DiGraph() if directed else nx.Graph()
    G.add_nodes_from(nodes)
    for u, v, w in edges:
        G.add_edge(u, v, weight=w)
    return G


def length(G, p):
    return sum(G[a][b]["weight"] for a, b in zip(p, p[1:]))


def brute_simple(G, s, t):
    """Every simple s-t path with its length, sorted by length (ties by vertex list)."""
    if s == t:
        return [(0, [s])]
    return sorted((length(G, p), p) for p in nx.all_simple_paths(G, s, t))


def simple(name, G, s, t, k=None):
    nx_paths = list(itertools.islice(nx.shortest_simple_paths(G, s, t, weight="weight"), k)) if s != t else [[s]]
    brute = brute_simple(G, s, t)[: k if k else None]
    assert [length(G, p) for p in nx_paths] == [d for d, _ in brute], (name, nx_paths, brute)
    print(f"--- {name} {s}->{t}: lengths {[d for d, _ in brute]}")
    groups = itertools.groupby(brute, key=lambda x: x[0])
    for d, ps in groups:
        print(f"  {d}: {sorted(p for _, p in ps)}")


def all_shortest(name, G, s, t, weighted=True):
    try:
        ps = sorted(nx.all_shortest_paths(G, s, t, weight="weight" if weighted else None))
    except nx.NetworkXNoPath:
        ps = []
    print(f"--- all shortest {name} {s}->{t}{'' if weighted else ' (unweighted)'}: {len(ps)} paths {ps}")


def bidirectional(name, G, s, t):
    try:
        d, p = nx.bidirectional_dijkstra(G, s, t)
    except nx.NetworkXNoPath:
        d, p = None, None
    print(f"--- bidirectional {name} {s}->{t}: {d} {p} (path tie-dependent)")


def all_pairs(name, G):
    vs = list(G.nodes)
    try:
        lengths = dict(nx.johnson(G, weight="weight"))
        D = [[None if b not in lengths[a] else length(G, lengths[a][b]) for b in vs] for a in vs]
        fw = nx.floyd_warshall(G, weight="weight")
        assert all(D[i][j] == (None if fw[a][b] == float("inf") else fw[a][b]) for i, a in enumerate(vs) for j, b in enumerate(vs))
        print(f"--- all pairs {name} {vs}:")
        for a, row in zip(vs, D):
            print(f"  {a}: {row}")
    except nx.NetworkXUnbounded:
        print(f"--- all pairs {name}: negative cycle")


XG = [("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
      ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6)]
YEN = [("C", "D", 3), ("C", "E", 2), ("D", "F", 4), ("E", "D", 1), ("E", "F", 2), ("E", "G", 3),
       ("F", "G", 2), ("F", "H", 1), ("G", "H", 2)]
CLRS = [(1, 2, 3), (1, 3, 8), (1, 5, -4), (2, 4, 1), (2, 5, 7), (3, 2, 4), (4, 1, 2), (4, 3, -5), (5, 4, 6)]
C7 = [(i, (i + 1) % 7, 1) for i in range(7)]
GRID = [(r * 3 + c, r * 3 + c + 1, 1) for r in range(3) for c in range(2)] + [(r * 3 + c, r * 3 + c + 3, 1) for r in range(2) for c in range(3)]
TWO = [(0, 1, 1), (1, 2, 1), (2, 3, 1), (0, 10, 1), (10, 20, 1), (20, 3, 1)]
JOHNSON_NX = [("0", "3", 3), ("0", "1", -5), ("0", "2", 2), ("1", "2", 4), ("2", "3", 1)]

print("================ N. k shortest simple paths")
simple("SP-160 NetworkX cycle_graph(7)", digraph(C7, False), 0, 3)
simple("SP-161 Yen's example (Wikipedia)", digraph(YEN), "C", "H")
simple("SP-162 NetworkX XG", digraph(XG), "s", "v")
simple("SP-163 3x3 grid, undirected, unit", digraph(GRID, False), 0, 8)
simple("SP-163 3x3 grid, directed right/down, unit", digraph(GRID), 0, 8)
print("================ N. all shortest paths")
all_shortest("SP-170 NetworkX two routes", digraph(TWO, False), 0, 3, weighted=False)
all_shortest("SP-171 3x3 grid, undirected", digraph(GRID, False), 0, 8, weighted=False)
all_shortest("SP-172 Yen's example", digraph(YEN), "C", "H")
all_shortest("SP-172 Yen's example, unweighted", digraph(YEN), "C", "H", weighted=False)
print("================ N. bidirectional Dijkstra")
bidirectional("SP-178 NetworkX XG", digraph(XG), "s", "v")
bidirectional("SP-178 NetworkX XG", digraph(XG), "v", "s")
bidirectional("SP-179 Yen's example", digraph(YEN), "C", "H")
bidirectional("SP-179 cycle_graph(7) undirected", digraph(C7, False), 0, 4)
print("================ N. all pairs")
all_pairs("SP-183 CLRS figure 25.6 (Johnson)", digraph(CLRS))
all_pairs("SP-184 NetworkX test_johnson", digraph(JOHNSON_NX))
all_pairs("SP-185 NetworkX XG", digraph(XG))
all_pairs("SP-186 a negative cycle", digraph([(0, 1, 1), (1, 2, -3), (2, 0, 1), (3, 0, 1)]))
