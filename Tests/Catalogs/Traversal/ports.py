from ref import *
def sym(edges):
    s=set()
    for u,v in edges: s.add((u,v)); s.add((v,u))
    return sorted(s)
def S_of(edges, verts=()):
    S={v:[] for v in verts}
    for u,v in edges: S.setdefault(u,[]); S.setdefault(v,[])
    for u,v in sorted(set(edges)): S[u].append(v)
    return S
print("--- NX TestDFS G (symmetric)")
G=sym([(0,1),(1,2),(1,3),(2,4),(3,0),(0,4)]); S=S_of(G)
ev=dfs_events(S,[0]); print("pre",preorder(ev),"post",postorder(ev),"tree",tree_edges(ev),classes(ev)); print(fmt(ev))
print("from 1:", preorder(dfs_events(S,[1])), "parents", parents_of(dfs_events(S,[1])))
D=sym([(0,1),(2,3)]); SD=S_of(D)
ev=dfs_events(SD,sorted(SD)); print("D whole pre",preorder(ev),"post",postorder(ev),"tree",tree_edges(ev)); print(fmt(ev))
print("D from 2", preorder(dfs_events(SD,[2])), "D post from 0", postorder(dfs_events(SD,[0])))
# descending sort
Sd={k:sorted(v,reverse=True) for k,v in S.items()}
print("desc tree", tree_edges(dfs_events(Sd,[0])))
print("--- NX depth-limited, tree T")
T=sym([(i,i+1) for i in range(6)]+[(2,7),(7,8),(8,9),(9,10)]); ST=S_of(T)
for s,l in [(0,2),(3,3),(4,3),(0,3),(3,1),(9,4),(5,1),(6,2)]:
    ev=dfs_events(ST,[s],depth_limit=l)
    print(f"s={s} limit={l} pre={preorder(ev)} post={postorder(ev)} tree={tree_edges(ev)} parents={dict(sorted(parents_of(ev).items()))}")
    if s in (5,6): print("  ", fmt(ev))
DD=sym([(0,1),(2,3),(2,7),(7,8),(8,9),(9,10)]); SDD=S_of(DD)
for s,l in [(1,2),(2,2),(7,2),(2,3)]:
    ev=dfs_events(SDD,[s],depth_limit=l); print(f"D2 s={s} limit={l} pre={preorder(ev)} post={postorder(ev)} parents={dict(sorted(parents_of(ev).items()))}")
ev=dfs_events(SDD,sorted(SDD),depth_limit=1); print("D2 whole limit1 pre", preorder(ev)); print("  ",fmt(ev))
print("--- NX TestBFS G sym")
G=sym([(0,1),(1,2),(1,3),(2,4),(3,4)]); S=S_of(G)
b=bfs_events(S,[0]); print("tree",tree_edges(b),"layers",layers(S,[0]),"parents",parents_of(b)); print(fmt(b))
for srcs in ([0],[0,0]): print("layers",srcs,layers(S,srcs))
Dd=[(0,1),(1,2),(1,3),(2,4),(3,4)]; Sr=S_of([(v,u) for u,v in Dd])
print("reverse from 4", tree_edges(bfs_events(Sr,[4])))
Ds=[(0,1),(0,2),(1,4),(1,3),(2,5)]; S2=S_of(Ds)
print("sorted asc", tree_edges(bfs_events(S2,[0])), "desc", tree_edges(bfs_events({k:sorted(v,reverse=True) for k,v in S2.items()},[0])))
C5=[(i,(i+1)%5) for i in range(5)]
for extra in ([],[(4,4)]):
    S5=S_of(C5+extra); print("cycle5",extra, fmt(bfs_events(S5,[0])))
C5b=C5+[(0,2),(1,5),(2,5)]; S5=S_of(C5b); print("cycle5+", fmt(bfs_events(S5,[0])), "dist", bfs_dist(S5,[0]))
T=sym([(i,i+1) for i in range(6)]+[(2,7),(7,8),(8,9),(9,10)]); ST=S_of(T)
print("T layers from 0", layers(ST,[0]))
print("T bfs from 9 tree", tree_edges(bfs_events(ST,[9])))
print("descendants_at_distance: path5 from 2 dist 2", [l for i,l in enumerate(layers(S_of(sym([(i,i+1) for i in range(4)])),[2])) if i==2])
H=[(0,1),(0,2),(1,3),(1,4),(2,5),(2,6)]; print("H layers from 0", layers(S_of(H),[0]))
print("K3 multi-source [0,1] events", fmt(bfs_events(S_of(sym([(0,1),(0,2),(1,2)])),[0,1])))
