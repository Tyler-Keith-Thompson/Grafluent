import sys, heapq
import networkx as nx
from collections import deque
from fixtures import *

def dfs_events(S, roots, prune=frozenset(), depth_limit=None):
    """CLRS DFS, iterative, successors in list order. Events: ('D',v) ('T',u,v) ('B',u,v) ('F',u,v) ('C',u,v) ('X',v)=finish"""
    color = {}; d = {}; ev = []; t = 0
    for r in roots:
        if r in color: continue
        color[r] = 'g'; d[r] = t; t += 1; ev.append(('D', r))
        stack = [(r, iter([] if r in prune or depth_limit == 0 else S[r]), 0)]
        while stack:
            u, it, du = stack[-1]
            adv = False
            for v in it:
                c = color.get(v)
                if c is None:
                    ev.append(('T', u, v))
                    color[v] = 'g'; d[v] = t; t += 1; ev.append(('D', v))
                    lim = depth_limit is not None and du + 1 >= depth_limit
                    stack.append((v, iter([] if (v in prune or lim) else S[v]), du + 1))
                    adv = True; break
                elif c == 'g': ev.append(('B', u, v))
                else: ev.append(('F' if d[u] < d[v] else 'C', u, v))
            if not adv:
                stack.pop(); color[u] = 'b'; t += 1; ev.append(('X', u))
    return ev

def bfs_events(S, sources):
    """Boost BFS: discover sources; pop u; for v: tree+discover or nontree; finish u"""
    seen = set(); ev = []; q = deque()
    for s in sources:
        if s in seen: continue
        seen.add(s); ev.append(('D', s)); q.append(s)
    while q:
        u = q.popleft()
        for v in S[u]:
            if v not in seen:
                seen.add(v); ev.append(('T', u, v)); ev.append(('D', v)); q.append(v)
            else: ev.append(('N', u, v))
        ev.append(('X', u))
    return ev

def preorder(ev): return [e[1] for e in ev if e[0]=='D']
def postorder(ev): return [e[1] for e in ev if e[0]=='X']
def tree_edges(ev): return [(e[1],e[2]) for e in ev if e[0]=='T']
def classes(ev):
    c = {'T':0,'B':0,'F':0,'C':0}
    for e in ev:
        if e[0] in c: c[e[0]] += 1
    return c
def bfs_dist(S, sources):
    dist = {}; q = deque()
    for s in sources:
        if s not in dist: dist[s]=0; q.append(s)
    while q:
        u=q.popleft()
        for v in S[u]:
            if v not in dist: dist[v]=dist[u]+1; q.append(v)
    return dist
def layers(S, sources):
    dist = bfs_dist(S, sources); L = {}
    order = preorder(bfs_events(S, sources))
    for v in order: L.setdefault(dist[v], []).append(v)
    return [L[k] for k in sorted(L)]
def parents_of(ev):
    return {v:u for (u,v) in tree_edges(ev)}

def topo_dfs(S, roots):
    ev = dfs_events(S, roots)
    if any(e[0]=='B' for e in ev): return None
    return list(reversed(postorder(ev)))
def first_back_cycle(S, roots):
    ev = dfs_events(S, roots); par = {}
    for e in ev:
        if e[0]=='T': par[e[2]] = e[1]
        if e[0]=='B':
            u, v = e[1], e[2]
            path = [u]
            while path[-1] != v: path.append(par[path[-1]])
            return list(reversed(path))  # v ... u, closing edge u->v
    return None
def kahn_fifo(S, verts):
    indeg = {v:0 for v in verts}
    for u in S:
        for v in S[u]: indeg[v]+=1
    q = deque(v for v in verts if indeg[v]==0); out=[]
    while q:
        u=q.popleft(); out.append(u)
        for v in S[u]:
            indeg[v]-=1
            if indeg[v]==0: q.append(v)
    return out if len(out)==len(verts) else ('cycle', out)
def lex_topo(S, verts, key=lambda x:x):
    indeg = {v:0 for v in verts}
    for u in S:
        for v in S[u]: indeg[v]+=1
    h=[(key(v),v) for v in verts if indeg[v]==0]; heapq.heapify(h); out=[]
    while h:
        _,u=heapq.heappop(h); out.append(u)
        for v in S[u]:
            indeg[v]-=1
            if indeg[v]==0: heapq.heappush(h,(key(v),v))
    return out if len(out)==len(verts) else ('cycle', out)
def generations(S, verts):
    indeg = {v:0 for v in verts}
    for u in S:
        for v in S[u]: indeg[v]+=1
    cur = sorted(v for v in verts if indeg[v]==0); gens=[]; done=0
    while cur:
        gens.append(cur); done+=len(cur); nxt=[]
        for u in cur:
            for v in S[u]:
                indeg[v]-=1
                if indeg[v]==0: nxt.append(v)
        cur = sorted(nxt)
    return gens if done==len(verts) else ('cycle', gens)

def nxdg(f):
    G = nx.DiGraph(); G.add_nodes_from(sorted(vertex_set(f))); G.add_edges_from(sorted(set(f['edges']))); return G

def fmt(ev):
    names = {'D':'discover','X':'finish','T':'treeEdge','B':'backEdge','F':'forwardEdge','C':'crossEdge','N':'nonTreeEdge'}
    out=[]
    for e in ev:
        if len(e)==2: out.append(f".{names[e[0]]}({e[1]!r})".replace("'",'"'))
        else: out.append(f".{names[e[0]]}({e[1]!r}→{e[2]!r})".replace("'",'"'))
    return ', '.join(out)
