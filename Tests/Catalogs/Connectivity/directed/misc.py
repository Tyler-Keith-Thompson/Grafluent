import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref
def w(e, v=()):
    return ref.written(dict(edges=e, listed=list(v)))
def show(t, V, S, roots=()):
    c, st = ref.tarjan(V, S)
    print(t, 'V=', V, 'scc=', c, 'stack=', st, 'cond=', ref.condensation(V, S, c), 'att=', ref.attracting(V, S, c), 'weak=', ref.weak(V, S))
    for r in roots:
        idom = ref.lengauer_tarjan(V, S, r); df = ref.frontiers(V, S, r, idom)
        print('   root', r, 'idom', idom, 'DF', {k: sorted(x) for k, x in df.items()})
show('parallel+loop', *w([(0,1),(0,1),(1,0),(1,1)]), roots=[0])
show('parallel only', *w([(0,1),(0,1)]), roots=[0])
show('loops only 2', *w([(0,0),(0,0)], [0,1]), roots=[0])
show('antiparallel+parallel', *w([(0,1),(0,1),(1,0)]))
show('spread ints', *w([(30,10),(10,20),(20,10),(20,40)]), roots=[30])
show('strings vertices c a b', *w([('a','b'),('b','a'),('c','a')], ['c','a','b']), roots=['c'])
show('scc9 multigraph from roots', *w([(6,0),(0,3),(3,6),(8,6),(8,2),(2,5),(5,8),(7,5),(1,7),(7,4),(4,1)]), roots=[1])
# JGraphT rotation of graph 6 (wikipedia), shift k: vertex v -> ((v-1+k) % 8)+1
e6 = [(1,5),(2,1),(3,2),(3,4),(4,3),(5,2),(6,2),(6,5),(6,7),(7,3),(7,6),(8,4),(8,7)]
for k in range(8):
    r = lambda v: ((v - 1 + k) % 8) + 1
    V, S = ref.ascending(dict(edges=[(r(a), r(b)) for a, b in e6], listed=list(range(1, 9))))
    c, _ = ref.tarjan(V, S)
    print('jgt6 rot', k, c)
