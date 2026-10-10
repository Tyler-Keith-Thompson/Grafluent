"""Real-world fixture statistics and deep/stress graphs."""
import sys, collections
sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
import networkx as nx
from fixtures import F
import ref

def stats(name, f, roots):
    V, S = ref.ascending(f)
    G = nx.DiGraph(); G.add_nodes_from(V); G.add_edges_from((u, w) for u in V for w in S[u])
    c, st = ref.tarjan(V, S)
    assert [set(x) for x in c] == list(nx.strongly_connected_components(G))
    sizes = collections.Counter(len(x) for x in c)
    w = ref.weak(V, S)
    rows = ref.condensation(V, S, c)
    att = ref.attracting(V, S, c)
    loops = sum(1 for u in V if u in S[u])
    print(f'{name}: n={len(V)} m={sum(len(S[u]) for u in V)} self-loops={loops}')
    print(f'   SCC count={len(c)} sizes(size:count)={dict(sorted(sizes.items()))} largest={max(map(len,c))}')
    print(f'   first 8 components={c[:8]}  last 3={c[-3:]}')
    big = max(c, key=len)
    print(f'   index of largest={c.index(big)} its first 10 members={big[:10]}')
    print(f'   condensation edges={sum(map(len, rows))} attracting count={len(att)} sizes={sorted(map(len,att), reverse=True)[:6]}')
    print(f'   weak count={len(w)} sizes={sorted(map(len,w), reverse=True)[:6]} first members={[x[0] for x in w][:8]}')
    print(f'   strongly={len(c)==1} weakly={len(w)==1}')
    assert len(att) == nx.number_attracting_components(G)
    assert len(w) == nx.number_weakly_connected_components(G)
    for r in roots:
        idom = ref.lengauer_tarjan(V, S, r)
        assert idom == nx.immediate_dominators(G, r)
        ch = ref.children(idom, V)
        depth = {r: 0}
        for v in ref.dfs_preorder_postorder({u: ch.get(u, []) for u in V}, r)[0]:
            for x in ch.get(v, []): depth[x] = depth[v] + 1
        df = nx.dominance_frontiers(G, r)
        assert df == ref.frontiers(V, S, r, idom)
        _, rounds = ref.chk(V, S, r)
        print(f'   dominators from {r}: reachable={len(idom)+1} idom==root={sum(1 for d in idom.values() if d==r)} '
              f'tree height={max(depth.values())} DF total={sum(map(len, df.values()))} nonempty={sum(1 for x in df.values() if x)} CHK rounds={rounds}')
        top = sorted(ch, key=lambda d: -len(ch[d]))[:3]
        print(f'      biggest fan-out: ' + ', '.join(f'{d}:{len(ch[d])}' for d in top) + f'; non-root idoms={sorted({d for d in idom.values() if d != r})[:15]}')

stats('gap4', F['gap4'], [0, 5])
stats('graph500Scale8', F['graph500Scale8'], [82, 17])
stats('ligraRMat', F['ligraRMat'], [0])

print('=== deep')
n = 100_000
V = list(range(n)); S = {v: [v + 1] if v + 1 < n else [] for v in V}
c, _ = ref.tarjan(V, S)
assert c == [[v] for v in reversed(V)]
print('path: components = [[99999], [99998], ..., [0]]; condensation rows: row k (component k = vertex n-1-k) -> [k-1]')
idom = ref.lengauer_tarjan(V, S, 0); assert all(idom[v] == v - 1 for v in range(1, n))
print('path dominators from 0: idom(v) = v-1')
S2 = {v: [(v + 1) % n] for v in V}
c, _ = ref.tarjan(V, S2); assert c == [V]
print('cycle: one component [0...99999]')
S3 = {v: [v + 1] if v + 1 < n else [1] for v in V}
c, _ = ref.tarjan(V, S3); assert c == [list(range(1, n)), [0]]
idom = ref.lengauer_tarjan(V, S3, 0); assert all(idom[v] == v - 1 for v in range(1, n))
df = ref.frontiers(V, S3, 0, idom)
assert df[0] == set() and all(df[v] == {1} for v in range(1, n))
print('lasso 0->1->...->99999->1: components [[1..99999],[0]]; idom(v)=v-1; DF(v)={1} for v>=1, DF(0)={}')
# two-entry bidirectional path, CHK's worst case
m = 100_000
V4 = list(range(m + 1)); S4 = {v: [] for v in V4}; S4[0] = [1, m]
for i in range(1, m): S4[i].append(i + 1); S4[i + 1].append(i)
for v in V4: S4[v].sort()
idom = ref.lengauer_tarjan(V4, S4, 0); assert all(d == 0 for d in idom.values()) and len(idom) == m
c, _ = ref.tarjan(V4, S4); assert c == [list(range(1, m + 1)), [0]]
print('two-entry bidirectional path 0->1, 0->m, i<->i+1 (m=100000): idom(v)=0 for all v; components [[1..m],[0]]; CHK needs m passes')
# star: hub with 99999 leaves both ways
S5 = {0: list(range(1, n))}; S5.update({v: [0] for v in range(1, n)})
c, _ = ref.tarjan(V, S5); assert c == [V]
print('bidirectional star: one component')
# in-star DAG for weak components
print('isolated 100000 vertices: 100000 strong and weak components, each [v], in vertex order')
