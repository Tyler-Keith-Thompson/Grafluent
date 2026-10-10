"""Covering phase 1: reference model and independent checks for every catalog row.

Run:  uv run --quiet --no-project --with networkx==3.7 [--with igraph==1.0.0] python3 ref.py [--stress] [--write]
      (add --with igraph to also check against igraph's independent-set functions)

What decides Expected, per entry point (api.md, Determinism), and what each row is checked by:

* maximumIndependentSet()     the lexicographically least maximum independent set by vertex index
  independenceNumber()        (of two, the one holding the least vertex of their symmetric
  minimumVertexCover()        difference); a vertex with a self-loop is never independent.
                              minimumVertexCover() is its complement. Model: the documented
                              algorithm (looped vertices out; per component, bipartite components by
                              a maximum matching and the lattice greedy, the rest by a search).
                              Checked: equal to a reference that knows nothing of components or
                              matchings (vertex-by-vertex greedy with an independence-number oracle,
                              NetworkX max_weight_clique on the complement), to brute force on small
                              graphs, and (with igraph) to the least of igraph's
                              largest_independent_vertex_sets.
* minimumVertexCover(         Koenig's cover from a maximum matching: Z = alternating reach from the
    bipartition:)             free left vertices, (L - Z) + (R & Z). Checked: equal to NetworkX
                              to_vertex_cover; size equal to the matching; by brute force, the unique
                              minimum cover with the most left vertices (so independent of the
                              matching).
* approximateMinimumVertex    Bar-Yehuda-Even local ratio (NetworkX min_weighted_vertex_cover) with
  Cover(weight:)              edges in position order, ties to the lesser vertex index. Checked:
                              equal to NetworkX whenever positions are in G.edges() order; always a
                              cover of weight <= 2 * optimum (brute force or max_weight_clique).
* maximalIndependentSet(      greedy in vertex order (seeds first), looped vertices never taken.
    containing:)              Checked: independent and maximal; NetworkX validates the seeds the same
                              way (raises where ours is nil); on loop-free graphs equal to NetworkX
                              dominating_set(G, start_with=first vertex) where that run pops in order.
* minimumDominatingSet()      the lexicographically least minimum dominating set. Checked: brute force
                              (first k-subset in combinations order with k = the domination number).
* approximateMinimumDominat-  greedy set cover (Chvatal; NetworkX min_weighted_dominating_set): least
  ingSet(weight:)             weight / newly dominated count, ties to the least vertex index. Checked:
                              equal to NetworkX (it scans nodes in order and keeps the first minimum);
                              dominating; weight <= H(max closed-neighbourhood size) * optimum.
* minimumEdgeCover()          Edmonds' maximum matching (MatchingModule's procedure, model copied
  minimumEdgeCover(matching:) from its ref.py) plus, for each uncovered vertex in vertex order, its
                              first incident edge. Checked: size n - nu (Gallai), equal to NetworkX
                              min_edge_cover's size and to brute force; with Hopcroft-Karp's matching,
                              equal to NetworkX bipartite.min_edge_cover.
* isVertexCover / isIndepen-  definitions. Checked: NetworkX is_dominating_set, is_edge_cover; igraph
  dentSet / isDominatingSet / is_independent_vertex_set (which ignores loops: noted).
  isEdgeCover
"""
import itertools
import os
import math
import random
import sys
from collections import deque
from fractions import Fraction

import networkx as nx
from networkx.algorithms import bipartite as nxb
from networkx.algorithms import approximation as nxa

assert nx.__version__ == "3.7"
try:
    import igraph
except ImportError:
    igraph = None

CASES = []
FAILS = []


def fail(cid, msg):
    FAILS.append(f"{cid}: {msg}")


# --------------------------------------------------------------------------------------------
# Graph notation
# --------------------------------------------------------------------------------------------

class G:
    """An undirected graph as the API sees it: vertices in order, edges at positions 0.."""

    def __init__(self, V, E, kind="graph", left=None, right=None, token=None, w=None):
        self.V = list(V)
        self.E = [tuple(e[:2]) for e in E]
        self.kind = kind          # graph | multigraph | bipartite
        self.left = left
        self.right = right
        self.token = token
        self.wt = w               # vertex weights in vertex order, or None
        self.idx = {v: i for i, v in enumerate(self.V)}
        for (u, v) in self.E:
            assert u in self.idx and v in self.idx, (u, v)
        pairs = [frozenset(e) for e in self.E]
        if kind != "multigraph":
            assert len(set(pairs)) == len(pairs), "parallel edges need kind=multigraph"
        if kind == "bipartite":
            assert self.V == list(left) + list(right)
            for (u, v) in self.E:
                assert u in left and v in right
        self.n = len(self.V)
        self.rows = [[] for _ in self.V]
        for e, (u, v) in enumerate(self.E):
            a, b = self.idx[u], self.idx[v]
            self.rows[a].append((b, e))
            self.rows[b].append((a, e))   # a self-loop is listed twice
        self.adj = [set() for _ in self.V]   # simple neighbours, no self
        self.loop = [False] * self.n
        for (u, v) in self.E:
            a, b = self.idx[u], self.idx[v]
            if a == b:
                self.loop[a] = True
            else:
                self.adj[a].add(b)
                self.adj[b].add(a)

    def weight(self, i):
        return 1 if self.wt is None else self.wt[i]

    def text(self):
        es = ", ".join(f"{u}-{v}" for (u, v) in self.E)
        if self.token:
            s = self.token
        elif self.kind == "bipartite":
            s = f"L {fmtl(self.left)}; R {fmtl(self.right)}; E [{es}]"
        else:
            tag = "multigraph " if self.kind == "multigraph" else ""
            s = f"{tag}V {fmtl(self.V)}; E [{es}]"
        if self.wt is not None:
            s += f"; w {fmtl(self.wt)}"
        return s

    def nx(self):
        H = nx.Graph()
        H.add_nodes_from(self.V)
        for (u, v) in self.E:
            H.add_edge(u, v)
        if self.wt is not None:
            for i, v in enumerate(self.V):
                H.nodes[v]["weight"] = self.wt[i]
        return H

    def names(self, idxs):
        return [self.V[i] for i in sorted(idxs)]


def fmtl(xs):
    return "[" + ", ".join(str(x) for x in xs) + "]"


class LCG:
    def __init__(self, seed):
        self.x = seed & (2**64 - 1)

    def next(self):
        self.x = (self.x * 6364136223846793005 + 1442695040888963407) % 2**64
        return self.x >> 33


def lcg(n, m, seed):
    r = LCG(seed)
    seen, E = set(), []
    while len(E) < m:
        u, v = r.next() % n, r.next() % n
        if u == v or frozenset((u, v)) in seen:
            continue
        seen.add(frozenset((u, v)))
        E.append((u, v))
    return G(range(n), E, token=f"lcg({n},{m},{seed})")


def lcgv(n, m, seed, k):
    """lcg(n,m,seed) with vertex weights: then n more draws, weight 1 + d % k."""
    g = lcg(n, m, seed)
    r = LCG(seed)
    seen, cnt = set(), 0
    while cnt < m:
        u, v = r.next() % n, r.next() % n
        if u == v or frozenset((u, v)) in seen:
            continue
        seen.add(frozenset((u, v)))
        cnt += 1
    w = [1 + r.next() % k for _ in range(n)]
    return G(g.V, g.E, token=f"lcgv({n},{m},{seed},{k})", w=w)


def lcgb(l, rr, m, seed):
    r = LCG(seed)
    seen, E = set(), []
    while len(E) < m:
        u, v = r.next() % l, l + r.next() % rr
        if (u, v) in seen:
            continue
        seen.add((u, v))
        E.append((u, v))
    return G(list(range(l + rr)), E, kind="bipartite", left=list(range(l)),
             right=list(range(l, l + rr)), token=f"lcgb({l},{rr},{m},{seed})")


def K(n):
    return G(range(n), [(i, j) for i in range(n) for j in range(i + 1, n)], token=f"K({n})")


def C(n):
    return G(range(n), [(i, (i + 1) % n) for i in range(n)], token=f"C({n})")


def P(n):
    return G(range(n), [(i, i + 1) for i in range(n - 1)], token=f"P({n})")


def S(k):
    return G(range(k + 1), [(0, i) for i in range(1, k + 1)], token=f"star({k})")


def W(k):
    E = [(0, i) for i in range(1, k + 1)] + [(i, i % k + 1) for i in range(1, k + 1)]
    return G(range(k + 1), E, token=f"wheel({k})")


def Kb(a, b):
    return G(range(a + b), [(i, a + j) for i in range(a) for j in range(b)], kind="bipartite",
             left=list(range(a)), right=list(range(a, a + b)), token=f"Kb({a},{b})")


def grid(r, c):
    E = []
    for i in range(r):
        for j in range(c):
            v = i * c + j
            if j + 1 < c:
                E.append((v, v + 1))
            if i + 1 < r:
                E.append((v, v + c))
    return G(range(r * c), E, token=f"grid({r},{c})")


def named(name):
    H = getattr(nx, name)()
    return G(list(H.nodes), list(H.edges), token=f"nx({name})")


def bip(L, R, E):
    return G(list(L) + list(R), E, kind="bipartite", left=list(L), right=list(R))


def gr(V, E, kind="graph", w=None):
    return G(V, E, kind=kind, w=w)


def withw(g, w):
    return G(g.V, g.E, kind=g.kind, left=g.left, right=g.right, token=g.token, w=w)


# --------------------------------------------------------------------------------------------
# Definitions
# --------------------------------------------------------------------------------------------

def is_vc(g, s):
    s = set(s)
    return all(g.idx[u] in s or g.idx[v] in s for (u, v) in g.E)


def is_is(g, s):
    s = set(s)
    return all(not (g.idx[u] in s and g.idx[v] in s) for (u, v) in g.E)


def is_ds(g, s):
    s = set(s)
    return all(v in s or g.adj[v] & s for v in range(g.n))


def is_ec(g, es):
    cov = set()
    for e in es:
        cov.update(g.idx[x] for x in g.E[e])
    return len(cov) == g.n


def is_maximal_is(g, s):
    s = set(s)
    return is_is(g, s) and all(v in s or g.loop[v] or g.adj[v] & s for v in range(g.n))


def lexkey(s, n):
    """Equal-size sets: the lesser holds the least vertex of the symmetric difference."""
    return [0 if v in s else 1 for v in range(n)]


# --------------------------------------------------------------------------------------------
# Brute force and reference oracles
# --------------------------------------------------------------------------------------------

def small(g):
    return g.n <= 16


def brute_mis(g):
    best = None
    for k in range(g.n, -1, -1):
        for c in itertools.combinations(range(g.n), k):   # combinations order = lex rule
            if is_is(g, c):
                return set(c)
    return best


def alpha_oracle(g, cand):
    """Independence number of the simple graph on cand (no loops among cand), by NetworkX."""
    cand = list(cand)
    if not cand:
        return 0
    H = nx.Graph()
    H.add_nodes_from(cand)
    cs = set(cand)
    for i in cand:
        for j in cand:
            if i < j and j not in g.adj[i]:
                H.add_edge(i, j)
    return nx.max_weight_clique(H, weight=None)[1]


def reference_mis(g):
    """Vertex-by-vertex greedy in index order with an independence-number oracle: no components,
    no matchings. Takes v when some maximum independent set extends the choices so far with v."""
    cand = set(v for v in range(g.n) if not g.loop[v])
    a = alpha_oracle(g, cand)
    chosen = set()
    for v in range(g.n):
        if v not in cand:
            continue
        rest = cand - {v} - g.adj[v]
        if 1 + alpha_oracle(g, rest) == a:
            chosen.add(v)
            cand = rest
            a -= 1
        else:
            cand = cand - {v}
    return chosen


def hk_simple(vs, adj, isleft):
    """Any maximum matching on a bipartite component (simple augmenting paths)."""
    mate = {}
    for u in vs:
        if not isleft[u]:
            continue
        seen = set()

        def aug(x):
            for y in sorted(adj[x]):
                if y in seen:
                    continue
                seen.add(y)
                if y not in mate or aug(mate[y]):
                    mate[y] = x
                    mate[x] = y
                    return True
            return False
        aug(u)
    return mate


def lattice_greedy(vs, adj, isleft, mate):
    """The lexicographically least maximum independent set of a bipartite component, from a
    maximum matching (api.md, Implementation notes)."""
    vs = sorted(vs)
    side_free = [v for v in vs if v not in mate]
    Z = set()
    q = deque()
    for v in side_free:
        Z.add(v)
        q.append(v)
    # Alternating reach from every free vertex: leave a vertex by unmatched edges when it is on
    # its free root's side, by its matched edge otherwise. Roots on both sides at once never meet.
    root_side = {v: isleft[v] for v in side_free}
    while q:
        v = q.popleft()
        if isleft[v] == root_side[v]:
            for u in adj[v]:
                if mate.get(v) != u and u not in Z:
                    Z.add(u)
                    root_side[u] = root_side[v]
                    q.append(u)
        else:
            u = mate.get(v)
            if u is not None and u not in Z:
                Z.add(u)
                root_side[u] = root_side[v]
                q.append(u)
    indep = set(v for v in Z if isleft[v] == root_side[v])
    core = [v for v in vs if v not in Z]
    # pairs keyed by left vertex; arcs X -> Y for each core edge xL - yR not matched
    pair = {}
    for v in core:
        pair[v] = v if isleft[v] else mate[v]
    succ = {pair[v]: set() for v in core}
    pred = {pair[v]: set() for v in core}
    for x in core:
        if not isleft[x]:
            continue
        for y in adj[x]:
            if y in pair and mate[x] != y:
                assert not isleft[y]
                succ[x].add(pair[y])
                pred[pair[y]].add(x)
    choice = {}

    def spread(start, val, nbrs):
        st = [start]
        choice[start] = val
        while st:
            X = st.pop()
            for Y in nbrs[X]:
                if Y not in choice:
                    choice[Y] = val
                    st.append(Y)
                else:
                    assert choice[Y] == val
    for v in core:
        X = pair[v]
        if X in choice:
            continue
        if isleft[v]:
            spread(X, "R", succ)      # v independent: its mate covers
        else:
            spread(X, "L", pred)
    for X, c in choice.items():
        indep.add(X if c == "R" else mate[X])
    return indep


def components(g, alive):
    seen, out = set(), []
    for s in range(g.n):
        if s not in alive or s in seen:
            continue
        comp, q = [s], deque([s])
        seen.add(s)
        while q:
            v = q.popleft()
            for u in sorted(g.adj[v]):
                if u in alive and u not in seen:
                    seen.add(u)
                    comp.append(u)
                    q.append(u)
        out.append(sorted(comp))
    return out


def two_color(g, comp):
    col = {comp[0]: True}
    q = deque([comp[0]])
    while q:
        v = q.popleft()
        for u in g.adj[v]:
            if u in col:
                if col[u] == col[v]:
                    return None
            else:
                col[u] = not col[v]
                q.append(u)
    return col


def mis_model(g):
    """The documented algorithm: looped vertices out; per component, bipartite ones through a
    maximum matching and the lattice greedy, the others by the lexicographic search (here the
    oracle greedy restricted to the component)."""
    alive = set(v for v in range(g.n) if not g.loop[v])
    out = set()
    for comp in components(g, alive):
        col = two_color(g, comp)
        if col is not None:
            adj = {v: g.adj[v] & alive for v in comp}
            mate = hk_simple(comp, adj, col)
            out |= lattice_greedy(comp, adj, col, mate)
        else:
            sub = G([g.V[v] for v in comp], [(g.V[a], g.V[b]) for a in comp for b in g.adj[a] if a < b and b in alive])
            loc = reference_mis(sub)
            out |= set(comp[i] for i in loc)
    return out


def brute_wvc(g):
    best = None
    for k in range(g.n + 1):
        for c in itertools.combinations(range(g.n), k):
            if is_vc(g, c):
                w = sum(g.weight(v) for v in c)
                if best is None or w < best:
                    best = w
    return best


def opt_wvc(g):
    """Least cover weight: total - heaviest independent set (looped vertices forced in)."""
    if small(g):
        return brute_wvc(g)
    cand = [v for v in range(g.n) if not g.loop[v]]
    H = nx.Graph()
    for v in cand:
        H.add_node(v, weight=g.weight(v))
    for i in cand:
        for j in cand:
            if i < j and j not in g.adj[i]:
                H.add_edge(i, j)
    best = nx.max_weight_clique(H, weight="weight")[1] if cand else 0
    return sum(g.weight(v) for v in range(g.n)) - best


def brute_mds(g):
    for k in range(g.n + 1):
        for c in itertools.combinations(range(g.n), k):
            if is_ds(g, c):
                return set(c)


def brute_wds(g):
    best = None
    for k in range(g.n + 1):
        for c in itertools.combinations(range(g.n), k):
            if is_ds(g, c):
                w = sum(g.weight(v) for v in c)
                if best is None or w < best:
                    best = w
    return best


# --------------------------------------------------------------------------------------------
# Models of the approximation and matching-based entry points
# --------------------------------------------------------------------------------------------

def bye_model(g):
    cost = [g.weight(v) for v in range(g.n)]
    cover = set()
    for (u, v) in g.E:
        a, b = g.idx[u], g.idx[v]
        if a > b:
            a, b = b, a
        if a in cover or b in cover:
            continue
        if cost[a] <= cost[b]:
            cover.add(a)
            cost[b] = cost[b] - cost[a]
        else:
            cover.add(b)
            cost[a] = cost[a] - cost[b]
    return cover


def greedy_ds_model(g):
    unc = set(range(g.n))
    chosen = set()
    closed = [g.adj[v] | {v} for v in range(g.n)]
    while unc:
        best, bk = None, None
        for v in range(g.n):
            if v in chosen:
                continue
            k = len(closed[v] & unc)
            if k == 0:
                continue
            key = Fraction(g.weight(v)) / k if not isinstance(g.weight(v), float) else g.weight(v) / k
            if best is None or key < bk:
                best, bk = v, key
        chosen.add(best)
        unc -= closed[best]
    return chosen


def maximal_is_model(g, seeds=()):
    s = [g.idx[x] for x in seeds]
    ss = set(s)
    for v in ss:
        if g.loop[v] or g.adj[v] & ss:
            return None
    taken = set(ss)
    blocked = set(ss)
    for v in ss:
        blocked |= g.adj[v]
    for v in range(g.n):
        if v in blocked or g.loop[v]:
            continue
        taken.add(v)
        blocked.add(v)
        blocked |= g.adj[v]
    return taken


def maximal_matching_model(g):
    cov, out = set(), []
    for e, (u, v) in enumerate(g.E):
        if u != v and u not in cov and v not in cov:
            out.append(e)
            cov.update((u, v))
    return out


def hk_model(g, left_order):
    """NetworkX hopcroft_karp_matching on index rows (copied from MatchingModule's ref.py)."""
    INFD = math.inf
    left = [g.idx[v] for v in left_order]
    isleft = [False] * g.n
    for v in left:
        isleft[v] = True
    pairL = {v: None for v in left}
    edgeL = {v: None for v in left}
    pairR = {v: None for v in range(g.n) if not isleft[v]}
    dist = {}

    def bfs():
        q = deque()
        for v in left:
            if pairL[v] is None:
                dist[v] = 0
                q.append(v)
            else:
                dist[v] = INFD
        dist[None] = INFD
        while q:
            v = q.popleft()
            if dist[v] < dist[None]:
                for (u, _) in g.rows[v]:
                    if dist[pairR[u]] == INFD:
                        dist[pairR[u]] = dist[v] + 1
                        q.append(pairR[u])
        return dist[None] != INFD

    def dfs(v):
        if v is not None:
            for (u, e) in g.rows[v]:
                if dist[pairR[u]] == dist[v] + 1:
                    if dfs(pairR[u]):
                        pairR[u] = v
                        pairL[v] = u
                        edgeL[v] = e
                        return True
            dist[v] = INFD
            return False
        return True

    while bfs():
        for v in left:
            if pairL[v] is None:
                dfs(v)
    return sorted(edgeL[v] for v in left if pairL[v] is not None)


def konig_model(g, left_order, es):
    left = set(g.idx[v] for v in left_order)
    mate = {}
    for e in es:
        a, b = g.idx[g.E[e][0]], g.idx[g.E[e][1]]
        mate[a] = b
        mate[b] = a
    Z = set(v for v in left if v not in mate)
    q = deque(sorted(Z))
    while q:
        v = q.popleft()
        if v in left:
            for (u, _) in g.rows[v]:
                if mate.get(v) != u and u not in Z:
                    Z.add(u)
                    q.append(u)
        else:
            u = mate.get(v)
            if u is not None and u not in Z:
                Z.add(u)
                q.append(u)
    return set(v for v in range(g.n) if (v in left) != (v in Z))


def edmonds_model(g):
    """MatchingModule's Edmonds procedure (copied from its ref.py)."""
    n = g.n
    mate = [-1] * n
    mateE = [-1] * n
    for r in range(n):
        if mate[r] != -1:
            continue
        label = [0] * n
        link = [-1] * n
        linkE = [-1] * n
        uf = list(range(n))

        def find(x):
            while uf[x] != x:
                uf[x] = uf[uf[x]]
                x = uf[x]
            return x

        def lca(x, y):
            marked = set()
            while True:
                if x != -1:
                    x = find(x)
                    if x in marked:
                        return x
                    marked.add(x)
                    x = -1 if mate[x] == -1 else link[mate[x]]
                x, y = y, x

        q = deque([r])
        label[r] = 1

        def blossom(x, y, a, e):
            while find(x) != a:
                link[x] = y
                linkE[x] = e
                y = mate[x]
                if label[y] == 2:
                    label[y] = 1
                    q.append(y)
                if find(x) == x:
                    uf[x] = a
                if find(y) == y:
                    uf[y] = a
                e = linkE[y]
                x = link[y]

        found = False
        while q and not found:
            v = q.popleft()
            for (w, e) in g.rows[v]:
                if find(v) == find(w) or label[w] == 2:
                    continue
                if label[w] == 0:
                    link[w] = v
                    linkE[w] = e
                    if mate[w] == -1:
                        t = w
                        while t != -1:
                            p = link[t]
                            nxt = mate[p]
                            mate[t], mate[p] = p, t
                            mateE[t] = mateE[p] = linkE[t]
                            t = nxt
                        found = True
                        break
                    label[w] = 2
                    label[mate[w]] = 1
                    q.append(mate[w])
                else:
                    a = lca(v, w)
                    blossom(v, w, a, e)
                    blossom(w, v, a, e)
    return sorted(set(mateE[v] for v in range(n) if mate[v] != -1))


def edge_cover_model(g, matching):
    if any(not g.rows[v] for v in range(g.n)):
        return None
    out = set(matching)
    cov = set()
    for e in matching:
        cov.update(g.idx[x] for x in g.E[e])
    for v in range(g.n):
        if v in cov:
            continue
        e = g.rows[v][0][1]
        out.add(e)
        cov.update(g.idx[x] for x in g.E[e])
    return sorted(out)


def brute_ec_size(g):
    m = len(g.E)
    for k in range(m + 1):
        for c in itertools.combinations(range(m), k):
            if is_ec(g, c):
                return k
    return None


def bipartition_canonical(g):
    """BipartiteGraphs' bipartition(): BFS per component from its least vertex (left), rows in
    incidentEdges order. Returns (left, right) in vertex order, or None."""
    side = [None] * g.n
    for s in range(g.n):
        if side[s] is not None:
            continue
        side[s] = 0
        q = deque([s])
        while q:
            v = q.popleft()
            for (u, _) in g.rows[v]:
                if side[u] is None:
                    side[u] = 1 - side[v]
                    q.append(u)
                elif side[u] == side[v]:
                    return None
    return ([g.V[v] for v in range(g.n) if side[v] == 0], [g.V[v] for v in range(g.n) if side[v] == 1])


def harmonic(k):
    return sum(Fraction(1, i) for i in range(1, k + 1))


# --------------------------------------------------------------------------------------------
# Case builders
# --------------------------------------------------------------------------------------------

def add(group, name, inp, call, expected, checks):
    CASES.append((group, name, inp, call, expected, checks))


def cid():
    return f"CV-{len(CASES)+1:03d}"


def igraph_lex_mis(g):
    if igraph is None:
        return None
    alive = [v for v in range(g.n) if not g.loop[v]]
    pos = {v: i for i, v in enumerate(alive)}
    es = [(pos[a], pos[b]) for a in alive for b in g.adj[a] if a < b and b in pos]
    H = igraph.Graph(n=len(alive), edges=es)
    if not alive:
        return set()
    sets = [set(alive[i] for i in s) for s in H.largest_independent_vertex_sets()]
    return min(sets, key=lambda s: lexkey(s, g.n))


def check_mis(c, g, got):
    chk = []
    ref = reference_mis(g)
    if ref != got:
        fail(c, f"model {sorted(got)} vs oracle reference {sorted(ref)}")
    chk.append("= oracle reference")
    if small(g):
        b = brute_mis(g)
        if b != got:
            fail(c, f"brute {sorted(b)} vs {sorted(got)}")
        chk.append("brute force")
    ig = igraph_lex_mis(g)
    if ig is not None:
        if ig != got:
            fail(c, f"igraph {sorted(ig)} vs {sorted(got)}")
        chk.append("least of igraph largest_independent_vertex_sets")
    return "; ".join(chk)


def case_mis(name, g):
    c = cid()
    got = mis_model(g)
    assert is_is(g, got)
    chk = check_mis(c, g, got)
    add("MaximumIS", name, g.text(), "maximumIndependentSet()", fmtl(g.names(got)), chk)


def case_alpha(name, g):
    c = cid()
    got = mis_model(g)
    chk = check_mis(c, g, got)
    a = len(got)
    if igraph is not None:
        alive = [v for v in range(g.n) if not g.loop[v]]
        pos = {v: i for i, v in enumerate(alive)}
        es = [(pos[x], pos[y]) for x in alive for y in g.adj[x] if x < y and y in pos]
        ia = igraph.Graph(n=len(alive), edges=es).independence_number() if alive else 0
        if ia != a:
            fail(c, f"igraph alpha {ia} vs {a}")
        chk = "igraph independence_number; " + chk
    add("IndependenceNumber", name, g.text(), "independenceNumber()", str(a), chk)


def case_vc(name, g):
    c = cid()
    mis = mis_model(g)
    cover = set(range(g.n)) - mis
    assert is_vc(g, cover)
    chk = check_mis(c, g, mis)
    if small(g):
        b = brute_wvc(withw(g, None))
        if b != len(cover):
            fail(c, "cover size")
    note = ""
    if g.kind == "bipartite":
        es = hk_model(g, g.left)
        if len(es) != len(cover):
            fail(c, "Koenig size")
        kc = konig_model(g, g.left, es)
        note = f"; size = maximum matching {len(es)}"
        if kc != cover:
            note += f"; NetworkX to_vertex_cover (most left vertices) is {fmtl(g.names(kc))}"
    add("MinimumVC", name, g.text(), "minimumVertexCover()", fmtl(g.names(cover)),
        "complement of maximumIndependentSet(); " + chk + note)


def case_konig(name, g, left=None):
    c = cid()
    if g.kind == "bipartite":
        L, R = g.left, g.right
        call = "minimumVertexCover(bipartition: g.bipartition()!)"
        bp = bipartition_canonical(g)
        if left is None:
            L, R = bp
    else:
        bp = bipartition_canonical(g)
        assert bp is not None
        L, R = bp
        call = "minimumVertexCover(bipartition: g.bipartition()!)"
    es = hk_model(g, L)
    kc = konig_model(g, L, es)
    H = g.nx()
    nm = nxb.hopcroft_karp_matching(H, top_nodes=L)
    nxc = set(g.idx[v] for v in nxb.to_vertex_cover(H, nm, top_nodes=L))
    if nxc != kc:
        fail(c, f"to_vertex_cover {sorted(nxc)} vs {sorted(kc)}")
    if len(kc) != len(es) or not is_vc(g, kc):
        fail(c, "Koenig size/validity")
    chk = f"= NetworkX to_vertex_cover; size = matching {len(es)}"
    if small(g):
        Ls = set(g.idx[v] for v in L)
        mins = [set(cc) for cc in itertools.combinations(range(g.n), len(kc)) if is_vc(g, cc)]
        assert all(len(m) >= len(kc) for m in mins)
        if len(kc) > 0 and any(is_vc(g, cc) for cc in itertools.combinations(range(g.n), len(kc) - 1)):
            fail(c, "not minimum")
        most = max(len(m & Ls) for m in mins)
        ext = [m for m in mins if len(m & Ls) == most]
        if len(ext) != 1 or ext[0] != kc:
            fail(c, "not the unique most-left cover")
        chk += "; brute force: the unique minimum cover with the most left vertices"
    lex = set(range(g.n)) - mis_model(g)
    if lex != kc:
        chk += f"; minimumVertexCover() is {fmtl(g.names(lex))}"
    add("KoenigVC", name, g.text() + f"; left {fmtl(L)}, right {fmtl(R)}", call, fmtl(g.names(kc)), chk)


def nx_edges_in_position_order(g):
    """Whether NetworkX's G.edges() lists the edges in position order (same orientation set)."""
    if g.kind == "multigraph":
        return False
    H = g.nx()
    order = [frozenset(e) for e in H.edges()]
    return order == [frozenset(e) for e in g.E]


def case_approx_vc(name, g, weighted):
    c = cid()
    got = bye_model(g)
    if not is_vc(g, got):
        fail(c, "not a cover")
    w = sum(g.weight(v) for v in got)
    opt = opt_wvc(g)
    if w > 2 * opt:
        fail(c, f"ratio {w} > 2*{opt}")
    chk = [f"weight {w} <= 2 x optimum {opt}"]
    if g.kind != "multigraph":
        H = g.nx()
        nxc = set(g.idx[v] for v in nxa.min_weighted_vertex_cover(H, weight="weight" if weighted else None))
        if nx_edges_in_position_order(g):
            if nxc != got:
                fail(c, f"NetworkX {sorted(nxc)} vs {sorted(got)}")
            chk.insert(0, "= NetworkX min_weighted_vertex_cover")
        elif nxc != got:
            chk.insert(0, f"NetworkX scans G.edges() (by node), a different order, and returns {fmtl(g.names(nxc))}")
        else:
            chk.insert(0, "= NetworkX min_weighted_vertex_cover")
    call = "approximateMinimumVertexCover(weight:)" if weighted else "approximateMinimumVertexCover()"
    exp = fmtl(g.names(got)) + (f"; weight {w}" if weighted else "")
    add("ApproxVC", name, g.text(), call, exp, "; ".join(chk))


def case_maximal_is(name, g, seeds=None):
    c = cid()
    got = maximal_is_model(g, seeds or ())
    call = "maximalIndependentSet()" if seeds is None else f"maximalIndependentSet(containing: {fmtl(seeds)})"
    chk = []
    H = g.nx()
    if seeds:
        try:
            nxr = nx.maximal_independent_set(H, nodes=seeds, seed=1)
            nxok = True
        except nx.NetworkXUnfeasible:
            nxok = False
        if (got is None) == nxok:
            fail(c, "nil vs NetworkX feasibility")
        chk.append("NetworkX raises NetworkXUnfeasible" if not nxok else "NetworkX accepts the seeds")
    if got is None:
        add("MaximalIS", name, g.text(), call, "nil", "; ".join(chk))
        return
    if not is_maximal_is(g, got):
        fail(c, "not maximal independent")
    chk.insert(0, "independent and maximal")
    if not any(g.loop) and g.n > 0 and g.kind != "multigraph":
        start = seeds[0] if seeds and len(seeds) == 1 else (g.V[0] if not seeds else None)
        if start is not None:
            d = set(g.idx[v] for v in nx.dominating_set(H, start_with=start))
            if d == got:
                chk.append(f"= NetworkX dominating_set(start_with: {start})")
    if any(g.loop):
        chk.append("looped vertices never taken (NetworkX's random choice can take one)")
    add("MaximalIS", name, g.text(), call, fmtl(g.names(got)), "; ".join(chk))


def case_mds(name, g):
    c = cid()
    got = brute_mds(g)
    # components: the lexicographically least minimum dominating set is the union per component
    alive = set(range(g.n))
    union = set()
    for comp in components(g, alive):
        sub = G([g.V[v] for v in comp], [(g.V[a], g.V[b]) for a in comp for b in g.adj[a] if a < b])
        union |= set(comp[i] for i in brute_mds(sub))
    if union != got:
        fail(c, "component decomposition differs")
    chk = "brute force (first subset of the domination number in combinations order); per-component union agrees"
    gr_ = greedy_ds_model(withw(g, None))
    if len(gr_) > len(got):
        chk += f"; greedy gives {len(gr_)}"
    add("MinimumDS", name, g.text(), "minimumDominatingSet()", fmtl(g.names(got)), chk)


def case_approx_ds(name, g, weighted):
    c = cid()
    got = greedy_ds_model(g)
    if not is_ds(g, got):
        fail(c, "not dominating")
    H = g.nx()
    nxs = set(g.idx[v] for v in nxa.min_weighted_dominating_set(H, weight="weight" if weighted else None))
    if nxs != got:
        fail(c, f"NetworkX {sorted(nxs)} vs {sorted(got)}")
    w = sum(g.weight(v) for v in got)
    chk = "= NetworkX min_weighted_dominating_set; dominating"
    if small(g) and g.n <= 14:
        opt = brute_wds(g)
        delta = max((len(g.adj[v]) + 1 for v in range(g.n)), default=1)
        if w > harmonic(delta) * opt + Fraction(1, 10**9):
            fail(c, "ratio bound")
        chk += f"; weight {w} <= H({delta}) x optimum {opt}"
    call = "approximateMinimumDominatingSet(weight:)" if weighted else "approximateMinimumDominatingSet()"
    exp = fmtl(g.names(got)) + (f"; weight {w}" if weighted else "")
    add("ApproxDS", name, g.text(), call, exp, chk)


def fmt_edges(g, es):
    return f"[{', '.join(str(e) for e in es)}] {{{', '.join(f'{g.E[e][0]}–{g.E[e][1]}' for e in es)}}}"


def case_ec(name, g):
    c = cid()
    mm = edmonds_model(g)
    got = edge_cover_model(g, mm)
    H = g.nx()
    if got is None:
        try:
            nx.min_edge_cover(H)
            if g.n:
                fail(c, "NetworkX found a cover")
        except nx.NetworkXException:
            pass
        add("MinimumEC", name, g.text(), "minimumEdgeCover()", "nil",
            "a vertex has no edge; NetworkX raises NetworkXException")
        return
    if not is_ec(g, got):
        fail(c, "not an edge cover")
    chk = []
    if g.n - len(mm) != len(got):
        fail(c, "Gallai")
    if g.kind != "multigraph":
        nxs = nx.min_edge_cover(H)
        nxk = len({frozenset(p) for p in nxs})
        if nxk != len(got):
            fail(c, f"NetworkX size {nxk} vs {len(got)}")
        chk.append("size = NetworkX min_edge_cover")
    chk.append(f"size n - nu = {g.n} - {len(mm)}")
    if len(g.E) <= 18:
        if brute_ec_size(g) != len(got):
            fail(c, "brute size")
        chk.append("brute force")
    add("MinimumEC", name, g.text(), "minimumEdgeCover()", fmt_edges(g, got), "; ".join(chk))


def case_ec_bip(name, g):
    c = cid()
    L = g.left
    mm = hk_model(g, L)
    got = edge_cover_model(g, mm)
    call = "minimumEdgeCover(matching: g.maximumBipartiteMatching())"
    H = g.nx()
    if got is None:
        add("MinimumEC", name, g.text(), call, "nil", "a vertex has no edge")
        return
    nxs = nxb.min_edge_cover(H, matching_algorithm=lambda G_: nxb.hopcroft_karp_matching(G_, top_nodes=L))
    nxset = {frozenset(p) for p in nxs}
    ours = {frozenset(g.E[e]) for e in got}
    if nxset != ours:
        fail(c, f"NetworkX bipartite.min_edge_cover {nxset} vs {ours}")
    if len(got) != g.n - len(mm):
        fail(c, "Gallai")
    add("MinimumEC", name, g.text(), call, fmt_edges(g, got),
        "= NetworkX bipartite.min_edge_cover (Hopcroft-Karp, same left); size n - nu")


def case_check(name, g, kind, arg):
    c = cid()
    H = g.nx()
    if kind == "vc":
        got = is_vc(g, [g.idx[x] for x in arg])
        call, chk = f"isVertexCover({fmtl(arg)})", "definition"
    elif kind == "is":
        got = is_is(g, [g.idx[x] for x in arg])
        call, chk = f"isIndependentSet({fmtl(arg)})", "definition"
        if igraph is not None:
            pos = {v: i for i, v in enumerate(g.V)}
            es = [(pos[u], pos[v]) for (u, v) in g.E]
            ig = igraph.Graph(n=g.n, edges=es).is_independent_vertex_set([pos[x] for x in arg])
            if ig == got:
                chk += "; = igraph is_independent_vertex_set"
            elif any(g.loop[g.idx[x]] for x in arg):
                chk += f"; igraph ignores self-loops and says {ig}"
            else:
                fail(c, "igraph disagrees")
    elif kind == "ds":
        got = is_ds(g, [g.idx[x] for x in arg])
        call = f"isDominatingSet({fmtl(arg)})"
        if nx.is_dominating_set(H, arg) != got:
            fail(c, "NetworkX is_dominating_set")
        chk = "= NetworkX is_dominating_set"
    elif kind == "ec":
        got = is_ec(g, arg)
        call = f"isEdgeCover({fmtl(arg)})"
        chk = "definition"
        if g.kind != "multigraph":
            if nx.is_edge_cover(H, [g.E[e] for e in arg]) != got:
                fail(c, "NetworkX is_edge_cover")
            chk = "= NetworkX is_edge_cover"
    add("Checks", name, g.text(), call, str(got).lower(), chk)


def case_trap(group, name, inp, call, why):
    add(group, name, inp, call, "trap", "precondition: " + why)


# --------------------------------------------------------------------------------------------
# The catalog
# --------------------------------------------------------------------------------------------

def build():
    E0 = gr([], [])
    one = gr([0], [])
    loop1 = gr([0], [(0, 0)])
    two = gr([0, 1], [])
    edge = gr([0, 1], [(0, 1)])
    loopedge = gr([0, 1], [(0, 0), (0, 1)])
    par = gr([0, 1, 2], [(0, 1), (1, 0), (1, 2)], kind="multigraph")
    tri = K(3)
    mixed = gr(range(8), [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)])
    letters = gr(["d", "a", "c", "b"], [("d", "a"), ("a", "c"), ("c", "b")])

    # ---------------- maximumIndependentSet ----------------
    for nm, g in [("empty graph", E0), ("one vertex", one), ("one vertex with a self-loop", loop1),
                  ("two isolated vertices", two), ("one edge: the lesser end", edge),
                  ("self-loop excludes its vertex", loopedge),
                  ("parallel edges count once", par), ("triangle", tri), ("K(5)", K(5)),
                  ("path P(2)", P(2)), ("path P(4): {0,2} beats {0,3}, {1,3}", P(4)), ("path P(5)", P(5)),
                  ("path P(6)", P(6)), ("cycle C(4)", C(4)), ("cycle C(5)", C(5)), ("cycle C(6)", C(6)),
                  ("cycle C(7)", C(7)), ("star(4): the leaves", S(4)), ("wheel(5)", W(5)), ("wheel(6)", W(6)),
                  ("Petersen", named("petersen_graph")), ("grid(3,4)", grid(3, 4)), ("grid(5,5)", grid(5, 5)),
                  ("Kb(2,3) as BipartiteGraph", Kb(2, 3)), ("Kb(3,3)", Kb(3, 3)),
                  ("mixed components: triangle, path, looped pendant", mixed),
                  ("vertex order, not label order", letters),
                  ("bipartite, interleaved vertex order", gr(range(6), [(0, 3), (3, 1), (1, 4), (4, 2), (2, 5), (5, 0)][:5])),
                  ("bipartite core: perfect matching, lattice choice", gr(range(6), [(0, 1), (1, 2), (2, 3), (3, 0), (0, 5), (4, 5)])),
                  ("odd cycle with pendant", gr(range(6), [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 5)])),
                  ("all vertices looped", gr(range(3), [(0, 0), (1, 1), (2, 2), (0, 1)])),
                  ("loop in a bipartite piece splits it", gr(range(5), [(0, 1), (1, 2), (2, 3), (3, 4), (2, 2)])),
                  ("nx(bull_graph)", named("bull_graph")), ("nx(house_graph)", named("house_graph")),
                  ("nx(krackhardt_kite_graph)", named("krackhardt_kite_graph")),
                  ("nx(frucht_graph)", named("frucht_graph")),
                  ("lcg(12,20,1)", lcg(12, 20, 1)), ("lcg(16,30,2)", lcg(16, 30, 2)),
                  ("lcg(24,40,3)", lcg(24, 40, 3)), ("lcgb(6,7,15,4) as BipartiteGraph", lcgb(6, 7, 15, 4)),
                  ("lcgb(10,10,25,5)", lcgb(10, 10, 25, 5))]:
        case_mis(nm, g)

    # ---------------- independenceNumber ----------------
    for nm, g in [("empty graph", E0), ("one vertex with a self-loop", loop1), ("C(7)", C(7)),
                  ("Petersen: 4", named("petersen_graph")), ("K(6): 1", K(6)), ("grid(4,4): 8", grid(4, 4)),
                  ("nx(dodecahedral_graph)", named("dodecahedral_graph")), ("lcg(20,45,6)", lcg(20, 45, 6))]:
        case_alpha(nm, g)

    # ---------------- minimumVertexCover ----------------
    for nm, g in [("empty graph", E0), ("one vertex", one), ("self-loop: its vertex", loop1),
                  ("one edge: the greater end", edge), ("loop and edge", loopedge),
                  ("parallel edges", par), ("triangle", tri), ("K(4)", K(4)), ("P(4)", P(4)), ("C(5)", C(5)),
                  ("star(5): the hub", S(5)), ("Petersen: 6", named("petersen_graph")),
                  ("Kb(2,3): the left side", Kb(2, 3)), ("Kb(3,2): the right side", Kb(3, 2)),
                  ("L [0,1,2]; R [3,4,5]: lex vs Koenig", bip([0, 1, 2], [3, 4, 5], [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)])),
                  ("BipartiteGraph with an isolated right vertex", bip([0, 1], [2, 3, 4], [(0, 2), (1, 2), (1, 3)])),
                  ("lcgb(8,6,18,7)", lcgb(8, 6, 18, 7)), ("grid(4,5)", grid(4, 5)),
                  ("mixed components", mixed), ("letters", letters), ("lcg(18,35,8)", lcg(18, 35, 8)),
                  ("wheel(7)", W(7))]:
        case_vc(nm, g)

    # ---------------- Koenig cover with a bipartition ----------------
    for nm, g in [("empty graph", E0), ("one edge", edge), ("P(4)", P(4)), ("P(5)", P(5)), ("C(6)", C(6)),
                  ("star(3)", S(3)), ("Kb(2,3)", Kb(2, 3)),
                  ("L [0,1,2]; R [3,4,5]", bip([0, 1, 2], [3, 4, 5], [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)])),
                  ("grid(3,3)", grid(3, 3)), ("grid(4,4)", grid(4, 4)), ("tree", gr(range(7), [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)])),
                  ("two components", gr(range(6), [(1, 0), (1, 2), (3, 4), (5, 4)])),
                  ("parallel edges", gr([0, 1, 2], [(0, 1), (0, 1), (1, 2)], kind="multigraph")),
                  ("lcgb(6,7,15,4)", lcgb(6, 7, 15, 4)), ("lcgb(9,5,20,9)", lcgb(9, 5, 20, 9))]:
        case_konig(nm, g)

    # ---------------- approximateMinimumVertexCover ----------------
    for nm, g in [("empty graph", E0), ("one edge", edge), ("self-loop", loop1), ("loop and edge", loopedge),
                  ("parallel edges", par), ("triangle", tri), ("P(5)", P(5)), ("C(6)", C(6)), ("star(4): hub first", S(4)),
                  ("star(4) leaves first", gr(range(5), [(1, 0), (2, 0), (3, 0), (4, 0)])),
                  ("K(5)", K(5)), ("Petersen", named("petersen_graph")),
                  ("positions not in NetworkX order", gr(range(4), [(2, 3), (0, 1), (1, 2)])),
                  ("lcg(16,30,2)", lcg(16, 30, 2))]:
        case_approx_vc(nm, g, weighted=False)
    for nm, g in [("one edge, heavier first end", gr([0, 1], [(0, 1)], w=[3, 1])),
                  ("equal weights: lesser index", gr([0, 1], [(0, 1)], w=[2, 2])),
                  ("star, heavy hub", withw(S(4), [10, 1, 1, 1, 1])),
                  ("star, light hub", withw(S(4), [1, 5, 5, 5, 5])),
                  ("path, residual costs carry", gr(range(4), [(0, 1), (1, 2), (2, 3)], w=[2, 3, 2, 3])),
                  ("zero weights", withw(C(4), [0, 1, 0, 1])),
                  ("triangle weighted", withw(K(3), [1, 2, 3])),
                  ("self-loop weighted", gr([0, 1], [(0, 0), (0, 1)], w=[5, 1])),
                  ("float weights", gr(range(3), [(0, 1), (1, 2)], w=[0.5, 0.75, 0.25])),
                  ("lcgv(12,20,3,9)", lcgv(12, 20, 3, 9)), ("lcgv(20,40,5,5)", lcgv(20, 40, 5, 5))]:
        case_approx_vc(nm, g, weighted=True)

    # ---------------- maximalIndependentSet ----------------
    for nm, g, seeds in [("empty graph", E0, None), ("one vertex", one, None), ("self-loop: empty", loop1, None),
                         ("P(5)", P(5), None), ("star(3): hub first", S(3), None),
                         ("star(3), seeded with a leaf", S(3), [1]), ("C(6)", C(6), None),
                         ("C(6) seeded {1, 4}", C(6), [1, 4]), ("seeds adjacent: nil", C(6), [1, 2]),
                         ("seed with a self-loop: nil", loopedge, [0]), ("loop skipped", loopedge, None),
                         ("Petersen", named("petersen_graph"), None), ("letters", letters, None),
                         ("repeated seed", P(3), [2, 2]), ("parallel edges", par, None),
                         ("lcg(16,30,2)", lcg(16, 30, 2), None), ("lcg(16,30,2) seeded", lcg(16, 30, 2), [5, 9])]:
        case_maximal_is(nm, g, seeds)

    # ---------------- minimumDominatingSet ----------------
    for nm, g in [("empty graph", E0), ("one vertex", one), ("self-loop", loop1), ("two isolated", two),
                  ("one edge", edge), ("parallel edges", par), ("P(3): the middle", P(3)), ("P(4)", P(4)),
                  ("P(7)", P(7)), ("C(6)", C(6)), ("star(5): the hub", S(5)), ("K(4)", K(4)),
                  ("Petersen: 3", named("petersen_graph")), ("grid(3,3)", grid(3, 3)), ("grid(4,4)", grid(4, 4)),
                  ("mixed components", mixed), ("letters", letters),
                  ("three branches", gr(range(7), [(0, 1), (0, 2), (0, 3), (1, 4), (2, 5), (3, 6), (1, 2), (2, 3)])),
                  ("lcg(14,20,10)", lcg(14, 20, 10))]:
        case_mds(nm, g)

    # ---------------- approximateMinimumDominatingSet ----------------
    for nm, g in [("empty graph", E0), ("one vertex", one), ("self-loop", loop1), ("P(3)", P(3)), ("P(6)", P(6)),
                  ("C(6)", C(6)), ("star(4)", S(4)), ("Petersen", named("petersen_graph")),
                  ("parallel edges", par), ("grid(4,4)", grid(4, 4)), ("letters", letters),
                  ("three branches", gr(range(7), [(0, 1), (0, 2), (0, 3), (1, 4), (2, 5), (3, 6), (1, 2), (2, 3)])),
                  ("lcg(14,20,10)", lcg(14, 20, 10))]:
        case_approx_ds(nm, g, weighted=False)
    for nm, g in [("star, heavy hub", withw(S(4), [10, 1, 1, 1, 1])),
                  ("star, cheap hub", withw(S(4), [2, 1, 1, 1, 1])),
                  ("ratio tie: least index", gr(range(4), [(0, 1), (2, 3), (1, 2)], w=[2, 4, 4, 2])),
                  ("zero weight vertex first", withw(P(4), [1, 1, 0, 1])),
                  ("float weights", withw(P(5), [0.3, 0.9, 0.3, 0.9, 0.3])),
                  ("lcgv(12,20,3,9)", lcgv(12, 20, 3, 9))]:
        case_approx_ds(nm, g, weighted=True)

    # ---------------- minimumEdgeCover ----------------
    for nm, g in [("empty graph", E0), ("isolated vertex: nil", one), ("self-loop covers its vertex", loop1),
                  ("one edge", edge), ("edge and isolated vertex: nil", gr([0, 1, 2], [(0, 1)])),
                  ("loop and edge: the matched edge covers both", loopedge),
                  ("uncovered vertex takes its first edge, a loop", gr([0, 1, 2], [(0, 1), (2, 2), (1, 2)])),
                  ("uncovered vertex takes its first edge", gr([0, 1, 2], [(0, 1), (1, 2), (2, 2)])),
                  ("parallel edges", par), ("P(3)", P(3)), ("P(4)", P(4)), ("triangle", tri), ("star(4)", S(4)),
                  ("C(5)", C(5)), ("K(4)", K(4)), ("Petersen", named("petersen_graph")),
                  ("blossom", gr(range(6), [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5)])),
                  ("lcg(12,20,1)", lcg(12, 20, 1))]:
        case_ec(nm, g)
    for nm, g in [("Kb(2,3)", Kb(2, 3)), ("L [0,1,2]; R [3,4,5]", bip([0, 1, 2], [3, 4, 5], [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)])),
                  ("isolated right vertex: nil", bip([0], [1, 2], [(0, 1)])), ("lcgb(6,7,15,4)", lcgb(6, 7, 15, 4))]:
        case_ec_bip(nm, g)

    # ---------------- checks ----------------
    case_check("empty set covers an edgeless graph", two, "vc", [])
    case_check("one end covers", edge, "vc", [1])
    case_check("loop needs its vertex", loopedge, "vc", [1])
    case_check("loop covered", loopedge, "vc", [0])
    case_check("repeats are fine", P(3), "vc", [1, 1])
    case_check("C(4) alternate", C(4), "vc", [0, 2])
    case_check("C(4) adjacent pair misses an edge", C(4), "vc", [0, 1])
    case_check("empty set", tri, "is", [])
    case_check("adjacent", tri, "is", [0, 1])
    case_check("looped vertex is not independent", loopedge, "is", [0])
    case_check("other vertex", loopedge, "is", [1])
    case_check("parallel edges", par, "is", [0, 2])
    case_check("repeats are fine", P(3), "is", [0, 0, 2])
    case_check("empty graph, empty set", E0, "ds", [])
    case_check("isolated vertex must be in", two, "ds", [0])
    case_check("hub dominates", S(4), "ds", [0])
    case_check("leaf does not", S(4), "ds", [1])
    case_check("self-loop irrelevant", loop1, "ds", [0])
    case_check("Petersen {0,2,6}?", named("petersen_graph"), "ds", [0, 2, 6])
    case_check("empty graph", E0, "ec", [])
    case_check("one edge", edge, "ec", [0])
    case_check("P(3) one edge misses", P(3), "ec", [0])
    case_check("loop covers its vertex", loop1, "ec", [0])
    case_check("parallel copy", par, "ec", [1, 2])

    # ---------------- traps ----------------
    case_trap("Traps", "negative vertex weight", "V [0, 1]; E [0-1]; w [-1, 2]",
              "approximateMinimumVertexCover(weight:)", "weights >= 0 (the 2-approximation needs it)")
    case_trap("Traps", "NaN weight", "V [0, 1]; E [0-1]; w [nan, 1]",
              "approximateMinimumVertexCover(weight:)", "no weight is NaN")
    case_trap("Traps", "negative weight, dominating", "V [0]; E []; w [-1]",
              "approximateMinimumDominatingSet(weight:)", "weights >= 0")
    case_trap("Traps", "seed not a vertex", "P(3)", "maximalIndependentSet(containing: [9])", "every seed is a vertex")
    case_trap("Traps", "check with a non-vertex", "P(3)", "isVertexCover([9])", "every element is a vertex")
    case_trap("Traps", "check with a non-position", "P(3)", "isEdgeCover([7])", "every element is a position of edges")
    case_trap("Traps", "matching from another graph", "P(3)", "minimumEdgeCover(matching: P(5).maximumMatching())",
              "matching.edges are positions of this graph (vertex count checked)")
    case_trap("Traps", "bipartition of another graph", "P(4)", "minimumVertexCover(bipartition: P(5).bipartition()!)",
              "the bipartition's vertex count is this graph's")


def stress():
    """Random graphs: the decomposition + lattice greedy against brute force (lex rule), Koenig
    against NetworkX, approximations against bounds and NetworkX."""
    rnd = random.Random(7)
    count = 0
    nontriv = 0
    for t in range(1500):
        n = rnd.randint(1, 11)
        # bipartite-heavy: random sides, interleaved order
        sides = [rnd.random() < 0.5 for _ in range(n)]
        E = set()
        for _ in range(rnd.randint(0, 2 * n)):
            a, b = rnd.randrange(n), rnd.randrange(n)
            if a == b:
                if rnd.random() < 0.05:
                    E.add((a, a))
                continue
            if t % 3 != 0 and sides[a] == sides[b]:
                continue
            E.add((min(a, b), max(a, b)))
        E = sorted(E)
        rnd.shuffle(E)
        g = gr(range(n), E)
        got = mis_model(g)
        if got != brute_mis(g):
            FAILS.append(f"stress {t}: lex MIS {sorted(got)} vs brute {sorted(brute_mis(g))} on {g.text()}")
        if set(range(n)) - got != set(range(n)) - brute_mis(g):
            pass
        if not is_maximal_is(g, maximal_is_model(g)):
            FAILS.append(f"stress {t}: maximal")
        cov = bye_model(g)
        if not is_vc(g, cov) or len(cov) > 2 * (n - len(got)):
            FAILS.append(f"stress {t}: BYE bound")
        mm_ends = set()
        for (u, v) in [g.E[e] for e in maximal_matching_model(g)]:
            mm_ends.update((g.idx[u], g.idx[v]))
        loops = set(v for v in range(n) if g.loop[v])
        if not loops and not cov <= mm_ends:
            FAILS.append(f"stress {t}: unit BYE not inside the maximal matching ends {g.text()} {sorted(cov)}")
        wg = withw(g, [rnd.randint(0, 5) for _ in range(n)])
        wc = bye_model(wg)
        if not is_vc(wg, wc) or sum(wg.weight(v) for v in wc) > 2 * brute_wvc(wg):
            FAILS.append(f"stress {t}: weighted BYE bound")
        d = brute_mds(g)
        gd = greedy_ds_model(g)
        if not is_ds(g, gd):
            FAILS.append(f"stress {t}: greedy DS")
        H = g.nx()
        if set(g.idx[v] for v in nxa.min_weighted_dominating_set(H)) != gd:
            FAILS.append(f"stress {t}: greedy DS vs NetworkX")
        mm = edmonds_model(g)
        ec = edge_cover_model(g, mm)
        if ec is not None and (not is_ec(g, ec) or len(ec) != n - len(mm)):
            FAILS.append(f"stress {t}: edge cover")
        bp = bipartition_canonical(g)
        if bp is not None and not any(g.loop):
            L, _ = bp
            es = hk_model(g, L)
            kc = konig_model(g, L, es)
            nxc = set(g.idx[v] for v in nxb.to_vertex_cover(H, nxb.hopcroft_karp_matching(H, top_nodes=L), top_nodes=L))
            nontriv += kc != set(range(n)) - got
            # another maximum matching (augmenting paths, reversed rows): the same cover
            Lset = set(g.idx[v] for v in L)
            alt = hk_simple(list(range(n))[::-1], {v: set(g.adj[v]) for v in range(n)}, {v: v in Lset for v in range(n)})
            alt_es = sorted(set(next(e for (b, e) in g.rows[a] if b == alt[a]) for a in alt if a in Lset))
            if konig_model(g, L, alt_es) != kc:
                FAILS.append(f"stress {t}: Koenig cover depends on the matching")
            if kc != nxc or len(kc) != n - len(got):
                FAILS.append(f"stress {t}: Koenig")
        count += 1
    print(f"stress: {count} random graphs agree ({nontriv} bipartite ones where the lexicographic cover differs from Koenig's)")


HEADER = """# Covering: case catalog (CV-001 – CV-{last}, {count} cases)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 [--with
igraph] python3 ref.py`; `--write` regenerates this file, `--stress` adds 1,500 random graphs).
Expected is the API's documented output (api.md, Determinism); the last column says what each row
was checked against. ref.py's docstring lists the reference for each entry point.

## Notation

* **Graphs.** `V [..]; E [..]`: vertices in order (their vertex indices), then edges at positions
  0, 1, …, each `u-v`. Rows list edge ends in position order (an `UndirectedAdjacencyList` built
  by inserting `E` in order; a self-loop twice). `multigraph` rows have parallel edges, so tests
  need an in-file `Graph` conformer whose rows are in position order. `L [..]; R [..]; E [..]` is a
  `BipartiteGraph(left:right:edges:)`, so `vertices` is L then R. `; w [..]` gives vertex weights
  in `vertices` order (the `weight:` closure); unweighted calls weigh every vertex 1.
* **Generators** (as MatchingModule's catalog). `K(n)` every pair i < j lexicographic; `C(n)`
  edges i–(i+1) mod n; `P(n)` the path; `star(k)` hub 0, edges 0–i; `wheel(k)` hub 0, spokes 0–i
  then rim i–(i mod k + 1); `Kb(a,b)` the `BipartiteGraph` with left 0..<a, right a..<a+b, edges
  row-major; `grid(r,c)` vertex i·c+j, edges right then down, row-major; `nx(name)` NetworkX's
  `name()` nodes and `edges()`. `lcg(n,m,seed)`: a 64-bit LCG, x ← x·6364136223846793005 +
  1442695040888963407 (mod 2⁶⁴), each draw x >> 33; an edge is two draws (u = d % n, v = d % n),
  skipped when u = v or the pair is already an edge, until m edges. `lcgv(n,m,seed,k)`: the same
  graph, then n more draws from the same generator, vertex weight 1 + d % k. `lcgb(l,r,m,seed)`: a
  `BipartiteGraph`, left 0..<l, right l..<l+r, an edge u = d % l, v = l + d % r, repeats skipped.
* **Vertex sets** are listed in `vertices` order (the result arrays). `; weight w` is the sum of
  the result's weights (tests sum it; the API returns only the vertices).
* **Edge covers.** `[..] {..}`: positions ascending and the pairs they join.
* **Koenig rows** give the sides of `g.bipartition()` (each component's least vertex left) as
  `left [..], right [..]`.
* **trap** rows are preconditions: tests run them as exit tests (`#expect(processExitsWith:)`).

| ID | Group | Case | Input | Call | Expected | Checked |
|---|---|---|---|---|---|---|
"""


def main():
    if "--stress" in sys.argv:
        stress()
    build()
    if FAILS:
        print("\n".join(FAILS))
        sys.exit(1)
    if "--write" in sys.argv:
        out = HEADER.replace("{last}", f"{len(CASES):03d}").replace("{count}", str(len(CASES)))
        for i, (grp, name, inp, call, exp, chk) in enumerate(CASES):
            out += f"| CV-{i+1:03d} | {grp} | {name} | {inp} | `{call}` | {exp} | {chk} |\n"
        open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cases.md"), "w").write(out)
    print(f"{len(CASES)} cases; all values agree" + ("" if igraph else " (igraph not installed: its checks skipped)"))


if __name__ == "__main__":
    main()
