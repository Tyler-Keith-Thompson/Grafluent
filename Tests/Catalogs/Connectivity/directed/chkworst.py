import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref, time
def g_ladder(n):
    V=list(range(n+1)); S={v:[] for v in V}
    S[0]=[1,n]
    for i in range(1,n):
        S[i].append(i+1); S[i+1].append(i)
    for v in V: S[v].sort()
    return V,S
def g_rev(n):
    # entries into the end of a forward chain, plus back edges i->i-1: DFS goes forward, info flows backward
    V=list(range(n+1)); S={v:[] for v in V}
    S[0]=[1]+[n]
    for i in range(1,n): S[i].append(i+1)
    for i in range(2,n+1): S[i].append(i-1)
    for v in V: S[v]=sorted(set(S[v]))
    return V,S
for name,g in [('ladder',g_ladder),('rev',g_rev)]:
    for n in (10,100,1000):
        V,S=g(n)
        t=time.time(); idom,r=ref.chk(V,S,0); t1=time.time()-t
        t=time.time(); lt=ref.lengauer_tarjan(V,S,0); t2=time.time()-t
        assert lt==idom
        print(name,n,'rounds',r,'chk %.3fs lt %.3fs'%(t1,t2), 'idom==0 for all:', all(d==0 for d in idom.values()))
