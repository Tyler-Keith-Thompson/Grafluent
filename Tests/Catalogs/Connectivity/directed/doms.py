"""Dominator cases: Boost's seven test sets (parsed from the test file), NetworkX's and petgraph's
graphs, and the fixtures. Every idom is checked by brute force, CHK, LT and NetworkX."""
import re, sys
sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
import networkx as nx
import ref
from fixtures import F

# Boost's seven test sets are parsed out of a boostorg/graph checkout (commit 1ee1a99), which is not
# kept in the repository: pass its path as BOOST_GRAPH=/path/to/graph.
import os
if not os.environ.get('BOOST_GRAPH'):
    sys.exit('set BOOST_GRAPH to a boostorg/graph checkout (commit 1ee1a99)')
R = os.path.join(os.environ['BOOST_GRAPH'], '')

def solve(title, edges, root, vertices=(), order='asc', show_df=True, post=None):
    f = dict(edges=list(edges), listed=list(vertices))
    V, S = (ref.ascending if order == 'asc' else ref.written)(f)
    G = nx.DiGraph(); G.add_nodes_from(V); G.add_edges_from((u, w) for u in V for w in S[u])
    idom = ref.lengauer_tarjan(V, S, root)
    c, rounds = ref.chk(V, S, root)
    _, b = ref.dominators_brute(V, S, root)
    assert idom == c == b == nx.immediate_dominators(G, root), title
    df = ref.frontiers(V, S, root, idom)
    assert df == ref.frontiers_brute(V, S, root) == nx.dominance_frontiers(G, root), title
    pos = {v: i for i, v in enumerate(V)}
    print(f'{title}: root={root!r} V={V}')
    print('   idom=' + '{' + ', '.join(f'{v!r}: {idom[v]!r}' for v in sorted(idom, key=pos.get)) + '}')
    unreach = [v for v in V if v != root and v not in idom]
    if unreach: print(f'   unreachable={unreach}')
    ch = ref.children(idom, V)
    print('   children=' + '{' + ', '.join(f'{d!r}: {ch[d]}' for d in sorted(ch, key=pos.get)) + '}')
    if show_df:
        print('   DF=' + '{' + ', '.join(f'{v!r}: {sorted(df[v], key=pos.get)}' for v in sorted(df, key=pos.get)) + '}')
    print(f'   CHK rounds={rounds}')
    if post is not None:
        P = ref.preds_of(V, S)
        pidom = ref.lengauer_tarjan(V, P, post)
        assert pidom == nx.immediate_dominators(G.reverse(copy=False), post)
        pdf = ref.frontiers(V, P, post, pidom)
        assert pdf == nx.dominance_frontiers(G.reverse(copy=False), post)
        print(f'   POST exit={post!r} ipdom=' + '{' + ', '.join(f'{v!r}: {pidom[v]!r}' for v in sorted(pidom, key=pos.get)) + '}')
        print('   POST DF=' + '{' + ', '.join(f'{v!r}: {sorted(pdf[v], key=pos.get)}' for v in sorted(pdf, key=pos.get)) + '}')
    return V, S, idom

# Boost test sets
src = open(R + 'test/dominator_tree_test.cpp').read()
body = src[src.index('DominatorCorrectnessTestSet testSet[7];'):src.index('for (size_t i = 0;')]
sets = {}
for m in re.finditer(r'testSet\[(\d+)\]\.(numOfVertices = (\d+)|edges\.push_back\(edge\((\d+), (\d+)\)\)|correctIdoms\.push_back\(([^;]*)\);)', body):
    i = int(m.group(1)); s = sets.setdefault(i, dict(n=0, e=[], idom=[]))
    if m.group(3): s['n'] = int(m.group(3))
    elif m.group(4): s['e'].append((int(m.group(4)), int(m.group(5))))
    else:
        t = m.group(6); s['idom'].append(None if 'max' in t else int(t))
titles = re.findall(r'//\s*(.*)\n\s*testSet\[(\d)\]\.numOfVertices', body)
print('=== Boost dominator_tree_test.cpp')
for i in sorted(sets):
    s = sets[i]
    V, S, idom = solve(f'boost set {i}', s['e'], 0, range(s['n']))
    exp = s['idom']
    got = [idom.get(v) for v in range(s['n'])]
    assert got == exp, (i, got, exp)
    print(f'   edges={s["e"]} n={s["n"]}  (Boost correctIdoms match; None = root/unreachable)')
print(titles)

print('=== NetworkX test_dominance')
solve('nx doc', [(1,2),(1,3),(2,5),(3,4),(4,5)], 1)
solve('nx doc post', [(1,2),(2,3),(2,4),(3,5),(4,5),(5,6)], 1, post=6)
solve('nx irreducible fig2', [(1,2),(2,1),(3,2),(4,1),(5,3),(5,4)], 5)
solve('nx irreducible fig4', [(1,2),(2,1),(2,3),(3,2),(4,2),(4,3),(5,1),(6,4),(6,5)], 6)
solve('nx domrel', [(1,2),(2,3),(2,4),(2,6),(3,5),(4,5),(5,2)], 1, post=6)
solve('nx boost fig1', [(0,1),(1,2),(1,3),(2,7),(3,4),(4,5),(4,6),(5,7),(6,4)], 0, post=7)
solve('nx unreachable path5 from 1', [(0,1),(1,2),(2,3),(3,4)], 1)
solve('nx cycle5', [(i,(i+1)%5) for i in range(5)], 0)
solve('nx singleton loop', [(0,0)], 0)
solve('nx discard issue', [('b0','b1'),('b1','b2'),('b2','b3'),('b3','b1'),('b1','b5'),('b5','b6'),('b5','b8'),('b6','b7'),('b8','b7'),('b7','b3'),('b3','b4')], 'b0')
solve('nx loop', [('a','b'),('b','c'),('b','a')], 'a')
solve('nx missing idoms', [('entry_1','b1'),('b1','b2'),('b2','b3'),('b3','exit'),('entry_2','b3')], 'entry_1')
solve('nx loops larger', [('entry','exit'),('entry','1'),('1','2'),('2','3'),('3','4'),('4','5'),('5','6'),('6','exit'),('6','2'),('5','3'),('4','4')], 'entry', order='written')

print('=== petgraph Lengauer–Tarjan figure 1 (r=0, a..l = 1..12)')
names = 'r a b c d e f g h i j k l'.split()
ix = {s: i for i, s in enumerate(names)}
pe = [('r','a'),('r','b'),('r','c'),('a','d'),('b','a'),('b','d'),('b','e'),('c','f'),('c','g'),('d','l'),('e','h'),('f','i'),('g','i'),('g','j'),('h','e'),('h','k'),('i','k'),('j','i'),('k','r'),('k','i'),('l','h')]
V, S, idom = solve('petgraph LT fig1 (letters)', pe, 'r', names, order='written')
solve('petgraph LT fig1 + isolated z', pe, 'r', names + ['z'], order='written', show_df=False)

print('=== fixtures (ascending)')
for name, root in [('house', 5), ('scc9', 1), ('scc9', 0), ('boost24', 7), ('petgraphEdgesDirected', 0), ('boostExample', 1),
                   ('igraphReverseEdges', 0), ('jgraphtMatrixCSV', 4), ('boostWebGraph', 0), ('neo4jDirected', 0),
                   ('petgraphCsr1', 1), ('pathWithChord', 0), ('completeDirected3', 0), ('directedCycle10', 0),
                   ('directedPath10', 0), ('petgraphBellmanFord', 0), ('jgraphtSparseDirected', 2), ('cube', 0), ('petersen', 0),
                   ('networkXFunctionGraph', 0), ('scipyConstructor2', 3), ('boostCsrUnsorted', 5)]:
    f = F[name]
    solve(f'{name}', f['edges'], root, f['listed'])
for name, root in [('petgraphDAG', 'a'), ('networkXABCD', 'A')]:
    f = F[name]
    solve(f'{name} (Multigraph written order)', f['edges'], root, f['listed'], order='written')
f = F['selfLoopsAndDuplicates']; solve('selfLoopsAndDuplicates (Multigraph)', f['edges'], 1, f['listed'], order='written')
f = F['selfLoopsAndDuplicates']; solve('selfLoopsAndDuplicates from 5 (Multigraph)', f['edges'], 5, f['listed'], order='written')
f = F['triangleWithReciprocalEdge']; solve('triangle (Multigraph)', f['edges'], 1, f['listed'], order='written')
f = F['house']; solve('house post-dominators: exit 0 (reverse graph)', f['edges'], 5, f['listed'], post=0)
f = F['petgraphEdgesDirected']; solve('petgraphEdgesDirected post exit 3', f['edges'], 0, f['listed'], post=3)
