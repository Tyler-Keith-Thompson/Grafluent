from ref import *
import io, contextlib
with contextlib.redirect_stdout(io.StringIO()):
    from ports import S_of, sym
def iddfs(S, s, t):
    # pathfinding semantics: simple paths, first found at minimal depth, successors in order
    def step(path, depth):
        if depth == 0: return 'none'
        if path[-1] == t: return 'found'
        best='imp'
        for n in S[path[-1]]:
            if n not in path:
                path.append(n); r=step(path, depth-1)
                if r=='found': return r
                if r=='none': best='none'
                path.pop()
        return best
    path=[s]; d=1
    while True:
        r=step(path,d)
        if r=='found': return path
        if r=='imp': return None
        d+=1
print("--- bidirectional (NetworkX, sorted insertion) and IDDFS on fixtures")
for nm,pairs in [('house',[(5,0),(5,1),(3,0),(0,5)]),('scc9',[(1,3),(1,0),(0,8),(6,6)]),('boost24',[(7,2),(7,0),(1,7),(23,3)]),('petgraphEdgesDirected',[(0,4),(4,3),(6,0),(2,5)]),('cube',[(0,7),(3,4)]),('petersen',[(0,7),(0,8)]),('directedCycle10',[(0,9),(9,8),(3,3)]),('petgraphDAG',[('a','g'),('d','c'),('g','a')]),('boostWebGraph',[(4,2),(2,4)])]:
    f=F[nm]; G=nxdg(f); S=succ_sorted(f)
    out=[]
    for s,t in pairs:
        try: bp=nx.bidirectional_shortest_path(G,s,t)
        except nx.NetworkXNoPath: bp=None
        ip=iddfs(S,s,t)
        d=bfs_dist(S,[s]).get(t)
        out.append(f"{s!r}→{t!r}: bidir={bp} iddfs={ip} dist={d}")
    print(nm, "; ".join(out))
print("NX test: cycle7 undirected 0->3", nx.bidirectional_shortest_path(nx.cycle_graph(7),0,3), "0->4", nx.bidirectional_shortest_path(nx.cycle_graph(7),0,4), "directed cycle 0->3", nx.bidirectional_shortest_path(nx.cycle_graph(7,create_using=nx.DiGraph()),0,3))
C7=S_of(sym([(i,(i+1)%7) for i in range(7)])); print(" iddfs cycle7 0->4", iddfs(C7,0,4), "0->3", iddfs(C7,0,3))
g=nx.grid_2d_graph(4,4); g=nx.convert_node_labels_to_integers(g, first_label=1, ordering='sorted'); print(" grid 1->12", nx.bidirectional_shortest_path(g,1,12), nx.shortest_path_length(g,1,12))
print("--- pathfinding bidir: a->e", )
print("--- LexBFS (labels, tie -> smallest vertex) on symmetric fixtures")
def lexbfs(S, V):
    label={v:[] for v in V}; out=[]; n=len(V)
    remaining=set(V)
    while remaining:
        v=max(sorted(remaining), key=lambda x: label[x])  # max label; sorted → first max is smallest vertex
        # max returns first max encountered in sorted order
        out.append(v); remaining.remove(v)
        for w in S[v]:
            if w in remaining: label[w].append(n-len(out))
    return out
def is_peo(S, order):
    # order = elimination order: for each v, later neighbors form a clique
    pos={v:i for i,v in enumerate(order)}
    for v in order:
        later=[w for w in S[v] if pos[w]>pos[v] and w!=v]
        for a in later:
            for b in later:
                if a!=b and b not in S[a]: return False
    return True
for nm,E_ in [('cube',F['cube']['edges']),('petersen',F['petersen']['edges']),('path5',sym([(i,i+1) for i in range(4)])),('K4',sym([(a,b) for a in range(4) for b in range(4) if a<b])),('C4',sym([(0,1),(1,2),(2,3),(3,0)])),('C4+chord',sym([(0,1),(1,2),(2,3),(3,0),(0,2)])),('jgrapht-lex-events',sym([(1,2),(1,3),(1,4),(2,4),(3,4)])),('nx-dfs-G',sym([(0,1),(1,2),(1,3),(2,4),(3,0),(0,4)])),('gem',sym([(0,1),(1,2),(2,3),(4,0),(4,1),(4,2),(4,3)]))]:
    S=S_of(E_); V=sorted(S); o=lexbfs(S,V); print(nm, o, "reverse is PEO:", is_peo(S, list(reversed(o))), "chordal(nx):", nx.is_chordal(nx.Graph([(u,v) for u in S for v in S[u]])))
