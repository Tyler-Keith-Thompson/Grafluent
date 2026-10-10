"""Cross-checks ref.py against NetworkX on every Grafluent fixture and on seeded random graphs."""
import random, sys
sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
import networkx as nx
from fixtures import F
import ref

def nxgraph(V, S):
    G = nx.DiGraph()
    G.add_nodes_from(V)
    for u in V:
        for w in S[u]:
            G.add_edge(u, w)
    return G

def check(name, V, S, roots=None):
    G = nxgraph(V, S)
    comps, stackorder = ref.tarjan(V, S)
    nxs = [set(c) for c in nx.strongly_connected_components(G)]
    # NetworkX iterates nodes and adjacency in insertion order, which we made equal to V and S
    # (deduplicated), so its Tarjan–Zwick variant must give the same component order.
    assert [set(c) for c in comps] == nxs, (name, comps, nxs)
    ko = ref.kosaraju(V, S)
    assert {frozenset(c) for c in ko} == {frozenset(c) for c in comps}, name
    assert {frozenset(c) for c in nx.kosaraju_strongly_connected_components(G)} == {frozenset(c) for c in comps}
    lab = ref.labels(comps)
    for u in V:
        for w in S[u]:
            assert lab[u] >= lab[w], (name, u, w)
    if V:
        assert nx.is_strongly_connected(G) == (len(comps) == 1)
        assert nx.is_weakly_connected(G) == (len(ref.weak(V, S)) == 1)
    w = ref.weak(V, S)
    assert {frozenset(c) for c in w} == {frozenset(c) for c in nx.weakly_connected_components(G)}
    assert [c[0] for c in w] == [min(c, key=V.index) for c in (set(x) for x in nx.weakly_connected_components(G))], name
    C = nx.condensation(G, [set(c) for c in comps])
    rows = ref.condensation(V, S, comps)
    assert sorted(C.edges()) == sorted((i, j) for i, r in enumerate(rows) for j in r)
    att = ref.attracting(V, S, comps)
    assert [set(c) for c in att] == [set(c) for c in nx.attracting_components(G)], name
    for r in (roots if roots is not None else V):
        idom = nx.immediate_dominators(G, r)
        mine = ref.lengauer_tarjan(V, S, r)
        c, _ = ref.chk(V, S, r)
        _, b = ref.dominators_brute(V, S, r)
        assert idom == mine == c == b, (name, r, idom, mine, c, b)
        df = nx.dominance_frontiers(G, r)
        assert df == ref.frontiers(V, S, r, mine) == ref.frontiers_brute(V, S, r), (name, r)
    return True

n = 0
for name, f in F.items():
    for kind in (ref.ascending, ref.written):
        V, S = kind(f)
        roots = V if len(V) <= 40 else V[:5]
        check(name, V, S, roots); n += 1
print('fixtures ok', n)

rng = random.Random(20261008)
cnt = 0
for nv in (0, 1, 2, 3, 5, 8, 12, 25, 40):
    for p in (0.05, 0.15, 0.3, 0.6):
        for _ in range(25):
            V = list(range(nv))
            S = {v: sorted({w for w in V if rng.random() < p}) for v in V}
            check('rand', V, S); cnt += 1
print('random ok', cnt)
