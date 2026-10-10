import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref
def asc(e, v=()): return ref.ascending(dict(edges=list(e), listed=list(v)))
def wr(e, v=()): return ref.written(dict(edges=list(e), listed=list(v)))
def show(t, V, S, roots=()):
    c,_ = ref.tarjan(V,S)
    print(t, 'V=',V,'scc=',c,'labels=',[ref.labels(c)[v] for v in V],'weak=',ref.weak(V,S),'cond=',ref.condensation(V,S,c),'att=',ref.attracting(V,S,c))
    for r in roots:
        idom = ref.lengauer_tarjan(V,S,r); df = ref.frontiers(V,S,r,idom); pos={v:i for i,v in enumerate(V)}
        print('  root',r,'idom',idom,'DF',{k: sorted(x,key=pos.get) for k,x in sorted(df.items(), key=lambda kv: pos[kv[0]])}, 'children', ref.children(idom,V))
lemon=[(1,3),(3,2),(2,1),(4,2),(4,3),(5,6),(6,5)]
show('lemon', *asc(lemon, range(1,7)))
show('lemon MG + 3->3, 3->2', *wr(sorted(lemon)+[(3,3),(3,2)], range(1,7)))
show('gonum1', *asc([(0,1),(1,2),(1,7),(2,3),(2,6),(3,4),(4,2),(4,5),(6,3),(6,5),(7,0),(7,6)]))
show('gonum2', *asc([(0,1),(0,2),(0,3),(1,2),(2,3),(3,1)]))
show('spread MG', *wr([(30,10),(10,20),(20,10),(20,40)], [30,10,20,40]))
show('pg connected comp +9,10', *asc([(6,0),(0,3),(3,6),(8,6),(8,2),(2,5),(5,8),(7,5),(1,7),(7,4),(4,1)], range(11)))
show('pg connected comp +9->10', *asc([(6,0),(0,3),(3,6),(8,6),(8,2),(2,5),(5,8),(7,5),(1,7),(7,4),(4,1),(9,10)], range(11)))
show('path3 reversed', *asc([(2,1),(1,0)]))
show('pg cond scc9+2->3', *asc([(6,0),(0,3),(3,6),(8,6),(8,2),(2,3),(2,5),(5,8),(7,5),(1,7),(7,4),(4,1)]))
show('MG house written', *wr([(5,3),(3,4),(3,2),(4,0),(4,1),(2,1),(1,0)]))
show('scc9 + 0->1', *asc([(6,0),(0,3),(3,6),(8,6),(8,2),(2,5),(5,8),(7,5),(1,7),(7,4),(4,1),(0,1)]))
for n in (5,10,20):
    show(f'path{n}', *asc([(i,i+1) for i in range(n-1)]), roots=[0])
    show(f'cycle{n}', *asc([(i,(i+1)%n) for i in range(n)]), roots=[0])
show('pathWithChord MG', *wr([(v,v+1) for v in range(5)] + [(1,3),(1,3)]), roots=[0])
show('path0..4 from 1', *asc([(0,1),(1,2),(2,3),(3,4)]), roots=[1])
show('trivial', *asc([], [0]), roots=[0])
show('loop', *asc([(0,0)]), roots=[0])
show('CN-73', *wr([(0,1),(0,1),(1,0),(1,1)]), roots=[0])
show('CN-74', *wr([(0,1),(0,1)]), roots=[0])
show('CN-75', *wr([(0,0),(0,0)],[0,1]), roots=[0])
