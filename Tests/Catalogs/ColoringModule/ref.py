"""ColoringModule phase 1: reference model and independent checks for every catalog row.

Run:  uv run --quiet --no-project --with networkx==3.7 [--with rustworkx==0.18.1] python3 ref.py
      [--stress] [--write]

Everything colours the simple graph underlying the input: self-loops ignored, parallel edges once
(api.md, Semantics). "degree" below is the simple degree (distinct other neighbours).

What decides Expected, per entry point (api.md, Determinism), and what each row is checked by:

* greedyColoring(strategy:)   first fit (the least colour no coloured neighbour has) in the
                              strategy's order:
  .largestFirst               degree descending, vertex index ascending on ties (Welsh-Powell).
                              Checked: equal to NetworkX greedy_color(G, "largest_first") on every
                              loop-free row (its stable sort is the same rule).
  .smallestLast               Matula-Beck: repeatedly remove a least-degree vertex (least index on
                              ties), colour in the reverse order. Checked: the order is a smallest-last
                              order (each vertex has minimum degree among those before it), colours
                              <= degeneracy + 1; equal to NetworkX where its set pops agree (noted).
  .saturationLargestFirst     DSatur as NetworkX: first the greatest degree, then the uncoloured
                              vertex with the most distinct neighbour colours, then the greatest
                              degree, then the least index. Checked: equal to NetworkX
                              greedy_color(G, "saturation_largest_first") on every loop-free row.
  .independentSet             colour class k is a maximal independent set of the uncoloured
                              vertices built by repeatedly taking the least-degree vertex (degree
                              in what is left, least index on ties) and removing it and its
                              neighbours. Checked: equal to NetworkX "independent_set" when its
                              set iteration is ascending (noted per row).
  .connectedSequentialBreadthFirst / DepthFirst: components by least vertex, each searched from
                              its least vertex, neighbours in row order. Checked: equal to NetworkX
                              connected_sequential_bfs / _dfs when arbitrary_element is the least
                              vertex (noted per row).
* greedyColoring(order:)      first fit in the given order (Boost sequential_vertex_coloring).
                              Checked: NetworkX greedy_color with a callable strategy.
* chromaticNumber()           the least k with a proper k-colouring. Checked: an independent
                              inclusion-exclusion count (Bjorklund-Husfeldt-Koivisto) when n <= 18,
                              else a clique of that size (certificate) or the literature value.
* lexicographicallyFirstMinimumColoring()
                              on each component, the lexicographically least colour vector (in
                              vertex order) among the component's colourings with chi(component)
                              colours. Checked: brute force over restricted-growth vectors for
                              small components, else a plain index-order backtracking with no
                              feasibility oracle; proper; chi colours.
* minimumColoring()           the exact search's optimal colouring renumbered by first appearance:
                              not modelled (it depends on the search), so Expected is chi and the
                              rule (proper, chi colours, first appearance), with the colours where
                              they are forced: a graph that is bipartite or has no edge gets its
                              two-colouring (each component's least vertex 0), as the catalog's
                              lexicographically first rows do, and a graph of at most 12 vertices
                              with only one such chi-colouring gets that one.
* edgeColoring()              Misra-Gries as documented in api.md (edges in position order, u the
                              lesser index, least-colour choices). Checked: proper, <= Delta + 1
                              colours (rustworkx misra_gries count printed when installed).
* bipartiteEdgeColoring()     Koenig alternating-path recolouring, edges in position order, Delta
                              colours; nil when not bipartite. Checked: proper, exactly Delta
                              colours, rustworkx bipartite_edge_color count.
* isVertexColoring / isEdgeColoring definitions. Checked: NetworkX is_coloring (differs on loops: noted).
"""
import itertools
import os
import random
import sys
from collections import deque

import networkx as nx

assert nx.__version__ == "3.7"
try:
    import rustworkx as rx
except ImportError:
    rx = None

sys.setrecursionlimit(100000)
CASES = []
FAILS = []


def fail(msg):
    FAILS.append(f"{cid()}: {msg}")


# --------------------------------------------------------------------------------------------
# Graph notation
# --------------------------------------------------------------------------------------------

class G:
    def __init__(self, V, E, kind="graph", left=None, right=None, token=None):
        self.V = list(V)
        self.E = [tuple(e) for e in E]
        self.kind = kind
        self.left, self.right, self.token = left, right, token
        self.idx = {v: i for i, v in enumerate(self.V)}
        pairs = [frozenset(e) for e in self.E]
        if kind != "multigraph":
            assert len(set(pairs)) == len(pairs), "parallel edges need kind=multigraph"
        self.n = len(self.V)
        self.ie = [[self.idx[u], self.idx[v]] for (u, v) in self.E]
        self.rows = [[] for _ in self.V]
        for e, (a, b) in enumerate(self.ie):
            self.rows[a].append((b, e))
            self.rows[b].append((a, e))
        # simple rows: distinct other neighbours, first appearance in row order
        self.srows = []
        for a in range(self.n):
            seen, r = set(), []
            for (b, _) in self.rows[a]:
                if b != a and b not in seen:
                    seen.add(b)
                    r.append(b)
            self.srows.append(r)
        self.adj = [set(r) for r in self.srows]
        self.loop = [any(b == a for (b, _) in self.rows[a]) for a in range(self.n)]
        self.deg = [len(r) for r in self.srows]

    def text(self):
        if self.token:
            return self.token
        es = ", ".join(f"{u}-{v}" for (u, v) in self.E)
        tag = "multigraph " if self.kind == "multigraph" else ""
        if self.kind == "bipartite":
            return f"L {fmtl(self.left)}; R {fmtl(self.right)}; E [{es}]"
        return f"{tag}V {fmtl(self.V)}; E [{es}]"

    def nx(self):
        H = nx.Graph()
        H.add_nodes_from(self.V)
        H.add_edges_from(self.E)
        return H

    def simple_edges(self):
        return [(a, b) for a in range(self.n) for b in self.srows[a] if a < b]

    def has_parallel(self):
        ps = [frozenset(e) for e in self.ie]
        return len(set(ps)) != len(ps)

    def max_multi_degree(self):
        d = [0] * self.n
        for (a, b) in self.ie:
            d[a] += 1
            d[b] += 1
        return max(d, default=0)


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


def crown(k):
    """Kb(k,k) minus the matching i-(k+i): left 0..<k, right k..<2k, edges row-major."""
    return G(range(2 * k), [(i, k + j) for i in range(k) for j in range(k) if i != j],
             kind="bipartite", left=list(range(k)), right=list(range(k, 2 * k)), token=f"crown({k})")


def crownx(k):
    """The crown with interleaved numbering: u_i = 2i, w_i = 2i + 1, edges 2i-(2j+1), i != j,
    row-major. Every degree is k - 1, so index order pairs u_i, w_i and first fit needs k colours."""
    return G(range(2 * k), [(2 * i, 2 * j + 1) for i in range(k) for j in range(k) if i != j],
             token=f"crownx({k})")


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


def queen(n):
    """Square i*n+j; an edge between two squares on one row, column or diagonal, pairs (a, b),
    a < b, lexicographic."""
    E = []
    for a in range(n * n):
        for b in range(a + 1, n * n):
            r1, c1, r2, c2 = a // n, a % n, b // n, b % n
            if r1 == r2 or c1 == c2 or abs(r1 - r2) == abs(c1 - c2):
                E.append((a, b))
    return G(range(n * n), E, token=f"queen({n})")


def named(name, *args):
    H = getattr(nx, name)(*args)
    tok = f"nx({name}{'' if not args else ',' + ','.join(map(str, args))})"
    return G(list(H.nodes), list(H.edges), token=tok)


def gr(V, E, kind="graph"):
    return G(V, E, kind=kind)


# --------------------------------------------------------------------------------------------
# Greedy models
# --------------------------------------------------------------------------------------------

def first_fit(g, order):
    col = [-1] * g.n
    for v in order:
        used = {col[w] for w in g.srows[v] if col[w] >= 0}
        c = 0
        while c in used:
            c += 1
        col[v] = c
    return col


def order_largest_first(g):
    return sorted(range(g.n), key=lambda v: (-g.deg[v], v))


def bz_order(g):
    """Batagelj-Zaversnik's removal order, exactly as Cliques' _cores (bins swapped in place)."""
    n = g.n
    if n == 0:
        return []
    degree = list(g.deg)
    md = max(degree)
    bin_ = [0] * (md + 1)
    for d in degree:
        bin_[d] += 1
    start = 0
    for d in range(md + 1):
        cnt = bin_[d]
        bin_[d] = start
        start += cnt
    vert, pos = [0] * n, [0] * n
    fill = list(bin_)
    for v in range(n):
        pos[v] = fill[degree[v]]
        vert[pos[v]] = v
        fill[degree[v]] += 1
    for i in range(n):
        v = vert[i]
        for u in g.srows[v]:
            if degree[u] > degree[v]:
                du, pu = degree[u], pos[u]
                pw = bin_[du]
                w = vert[pw]
                if u != w:
                    pos[u], vert[pu], pos[w], vert[pw] = pw, w, pu, u
                bin_[du] += 1
                degree[u] -= 1
    return vert


def removal_smallest_last(g):
    """Matula-Beck: repeatedly remove a vertex of least degree in what is left, the least index
    on ties."""
    rem = set(range(g.n))
    deg = list(g.deg)
    out = []
    while rem:
        v = min(rem, key=lambda x: (deg[x], x))
        out.append(v)
        rem.discard(v)
        for w in g.adj[v]:
            if w in rem:
                deg[w] -= 1
    return out


def order_smallest_last(g):
    return list(reversed(removal_smallest_last(g)))


def is_smallest_last(g, order):
    """Each vertex has the least degree among itself and the vertices before it (in their
    induced subgraph): the removal order, reversed, always removes a minimum-degree vertex."""
    rem = set(order)
    for v in reversed(order):
        dv = len(g.adj[v] & rem)
        if any(len(g.adj[w] & rem) < dv for w in rem):
            return False
        rem.discard(v)
    return True


def dsatur_model(g):
    col = [-1] * g.n
    if g.n == 0:
        return col, []
    order = []
    for step in range(g.n):
        best, bkey = None, None
        for v in range(g.n):
            if col[v] >= 0:
                continue
            sat = len({col[w] for w in g.srows[v] if col[w] >= 0})
            key = (sat, g.deg[v])
            if bkey is None or key > bkey:
                best, bkey = v, key
        used = {col[w] for w in g.srows[best] if col[w] >= 0}
        c = 0
        while c in used:
            c += 1
        col[best] = c
        order.append(best)
    return col, order


def independent_set_order(g):
    """Classes as lists, each built by min-degree-in-what-is-left, least index on ties."""
    remaining = set(range(g.n))
    classes = []
    while remaining:
        avail = set(remaining)
        cls = []
        while avail:
            v = min(avail, key=lambda x: (len(g.adj[x] & avail), x))
            cls.append(v)
            avail -= g.adj[v] | {v}
        remaining -= set(cls)
        classes.append(cls)
    return [v for cls in classes for v in cls], classes


def components(g):
    seen = [False] * g.n
    comps = []
    for r in range(g.n):
        if seen[r]:
            continue
        seen[r] = True
        q, comp = deque([r]), []
        while q:
            v = q.popleft()
            comp.append(v)
            for w in g.srows[v]:
                if not seen[w]:
                    seen[w] = True
                    q.append(w)
        comps.append(sorted(comp))
    return comps


def order_bfs(g):
    seen = [False] * g.n
    out = []
    for r in range(g.n):
        if seen[r]:
            continue
        seen[r] = True
        q = deque([r])
        while q:
            v = q.popleft()
            out.append(v)
            for w in g.srows[v]:
                if not seen[w]:
                    seen[w] = True
                    q.append(w)
    return out


def order_dfs(g):
    seen = [False] * g.n
    out = []
    for r in range(g.n):
        if seen[r]:
            continue
        seen[r] = True
        out.append(r)
        stack = [(r, iter(g.srows[r]))]
        while stack:
            v, it = stack[-1]
            for w in it:
                if not seen[w]:
                    seen[w] = True
                    out.append(w)
                    stack.append((w, iter(g.srows[w])))
                    break
            else:
                stack.pop()
    return out


STRATS = {
    "largestFirst": ("largest_first", lambda g: first_fit(g, order_largest_first(g))),
    "smallestLast": ("smallest_last", lambda g: first_fit(g, order_smallest_last(g))),
    "saturationLargestFirst": ("saturation_largest_first", lambda g: dsatur_model(g)[0]),
    "independentSet": ("independent_set", lambda g: first_fit(g, independent_set_order(g)[0])),
    "connectedSequentialBreadthFirst": ("connected_sequential_bfs", lambda g: first_fit(g, order_bfs(g))),
    "connectedSequentialDepthFirst": ("connected_sequential_dfs", lambda g: first_fit(g, order_dfs(g))),
}


def proper(g, col):
    return all(col[a] != col[b] for (a, b) in g.ie if a != b)


def ncolors(col):
    return max(col) + 1 if col else 0


def nx_color_vec(g, d):
    return [d[v] for v in g.V]


# --------------------------------------------------------------------------------------------
# Exact: chromatic number and the lexicographically least optimal colouring
# --------------------------------------------------------------------------------------------

def sub_adj(g, comp):
    loc = {v: i for i, v in enumerate(comp)}
    return [[loc[w] for w in g.srows[v]] for v in comp]


def is_bip(adj):
    side = [-1] * len(adj)
    for r in range(len(adj)):
        if side[r] >= 0:
            continue
        side[r] = 0
        q = deque([r])
        while q:
            v = q.popleft()
            for w in adj[v]:
                if side[w] < 0:
                    side[w] = 1 - side[v]
                    q.append(w)
                elif side[w] == side[v]:
                    return False
    return True


def colorable(adj, k, fixed):
    """Is there a proper colouring with colours 0..k-1 extending `fixed` (dict)? DSatur-style
    search: branch on the uncoloured vertex with the fewest available colours."""
    n = len(adj)
    col = [-1] * n
    for v, c in fixed.items():
        col[v] = c
    for v in range(n):
        if col[v] >= 0 and any(col[w] == col[v] for w in adj[v]):
            return False
    full = (1 << k) - 1

    def avail(v):
        m = full
        for w in adj[v]:
            if col[w] >= 0:
                m &= ~(1 << col[w])
        return m

    def rec(left):
        if left == 0:
            return True
        best, bm, bc = -1, 0, 99
        for v in range(n):
            if col[v] < 0:
                m = avail(v)
                c = bin(m).count("1")
                if c == 0:
                    return False
                if c < bc:
                    best, bm, bc = v, m, c
        # symmetry: colours above the greatest used one are interchangeable
        hi = max(col) if max(col) >= 0 else -1
        tried_new = False
        for c in range(k):
            if bm >> c & 1:
                if c > hi:
                    if tried_new:
                        continue
                    tried_new = True
                col[best] = c
                if rec(left - 1):
                    return True
                col[best] = -1
        return False

    return rec(n - len(fixed))


def chi_adj(adj):
    n = len(adj)
    if n == 0:
        return 0
    if all(not a for a in adj):
        return 1
    if is_bip(adj):
        return 2
    # upper bound from DSatur, lower bound from a clique
    H = nx.Graph()
    H.add_nodes_from(range(n))
    H.add_edges_from((a, b) for a in range(n) for b in adj[a] if a < b)
    clique = max(nx.find_cliques(H), key=len)
    lo = max(3, len(clique))
    gs = G(range(n), list(H.edges))
    hi = ncolors(dsatur_model(gs)[0])
    for k in range(lo, hi):
        fixed = {v: i for i, v in enumerate(clique)}
        if colorable(adj, k, fixed):
            return k
    return hi


def chromatic_number(g):
    return max((chi_adj(sub_adj(g, c)) for c in components(g)), default=0)


def lex_least_adj(adj, k):
    """Lexicographically least proper colouring with colours < k (index order)."""
    n = len(adj)
    col = [-1] * n
    for v in range(n):
        used = {col[w] for w in adj[v] if w < v}
        c = 0
        while c in used:
            c += 1
        col[v] = c
    if n == 0 or max(col) < k:
        return col
    fixed = {}
    hi = -1
    for v in range(n):
        for c in range(min(k, hi + 2)):
            if any(fixed.get(w) == c for w in adj[v]):
                continue
            fixed[v] = c
            if colorable(adj, k, fixed):
                break
            del fixed[v]
        else:
            raise AssertionError("no extension")
        hi = max(hi, fixed[v])
    return [fixed[v] for v in range(n)]


def minimum_coloring_model(g):
    col = [0] * g.n
    for comp in components(g):
        adj = sub_adj(g, comp)
        k = chi_adj(adj)
        cc = lex_least_adj(adj, k)
        for i, v in enumerate(comp):
            col[v] = cc[i]
    return col


def brute_lex_adj(adj, k):
    """First restricted-growth vector in lexicographic order that is proper with < k colours."""
    n = len(adj)

    def rec(v, col, hi):
        if v == n:
            return list(col)
        for c in range(min(k, hi + 2)):
            col.append(c)
            if all(col[w] != c for w in adj[v] if w < v):
                r = rec(v + 1, col, max(hi, c))
                if r is not None:
                    return r
            col.pop()
        return None

    if n == 0:
        return []
    return rec(0, [], -1)


def plain_lex_adj(adj, k):
    """Index-order backtracking with forward checking only (no colourability oracle)."""
    n = len(adj)
    col = [-1] * n

    def rec(v, hi):
        if v == n:
            return True
        for c in range(min(k, hi + 2)):
            if any(col[w] == c for w in adj[v] if col[w] >= 0):
                continue
            col[v] = c
            ok = True
            for w in adj[v]:
                if col[w] < 0:
                    av = [d for d in range(k) if all(col[x] != d for x in adj[w])]
                    if not av:
                        ok = False
                        break
            if ok and rec(v + 1, max(hi, c)):
                return True
            col[v] = -1
        return False

    if n == 0:
        return []
    assert rec(0, -1)
    return col


def chi_inclusion_exclusion(g):
    """Bjorklund-Husfeldt-Koivisto: chi <= k iff sum_S (-1)^(n-|S|) i(S)^k > 0."""
    n = g.n
    if n == 0:
        return 0
    nb = [0] * n
    for v in range(n):
        for w in g.adj[v]:
            nb[v] |= 1 << w
    N = 1 << n
    ind = [0] * N
    ind[0] = 1
    for S_ in range(1, N):
        v = (S_ & -S_).bit_length() - 1
        ind[S_] = ind[S_ & ~(1 << v)] + ind[S_ & ~(1 << v) & ~nb[v]]
    pc = [bin(S_).count("1") for S_ in range(N)]
    for k in range(1, n + 1):
        tot = 0
        for S_ in range(N):
            t = ind[S_] ** k
            tot += -t if (n - pc[S_]) & 1 else t
        if tot > 0:
            return k
    return n


LITERATURE_CHI = {"nx(mycielski_graph,5)": 5, "queen(6)": 7, "queen(7)": 7, "nx(mycielski_graph,4)": 4,
                  "nx(chvatal_graph)": 4, "queen(5)": 5}


# --------------------------------------------------------------------------------------------
# Edge colouring models
# --------------------------------------------------------------------------------------------

class EC:
    def __init__(self, g):
        self.g = g
        self.col = [-1] * len(g.ie)
        self.at = [dict() for _ in range(g.n)]  # vertex -> colour -> edge

    def other(self, e, x):
        a, b = self.g.ie[e]
        return b if a == x else a

    def free(self, x, c):
        return c not in self.at[x]

    def least_free(self, x):
        c = 0
        while c in self.at[x]:
            c += 1
        return c

    def set(self, e, c):
        a, b = self.g.ie[e]
        assert self.free(a, c) and self.free(b, c), "colour clash"
        self.col[e] = c
        self.at[a][c] = e
        self.at[b][c] = e

    def unset(self, e):
        a, b = self.g.ie[e]
        c = self.col[e]
        del self.at[a][c]
        del self.at[b][c]
        self.col[e] = -1

    def flip_path(self, start, c1, c2):
        """Swap c1 and c2 on the maximal path from `start` whose first edge has colour c1."""
        path, x, c = [], start, c1
        while c in self.at[x]:
            e = self.at[x][c]
            path.append(e)
            x = self.other(e, x)
            c = c2 if c == c1 else c1
        olds = [self.col[e] for e in path]
        for e in path:
            self.unset(e)
        for e, o in zip(path, olds):
            self.set(e, c2 if o == c1 else c1)


def misra_gries_model(g):
    ec = EC(g)
    D = max(g.deg, default=0)
    for e, (a, b) in enumerate(g.ie):
        u, v = (a, b) if a < b else (b, a)
        # fan of u starting at v, extended until the least colour free at u, c, is free at its
        # last vertex, or until it is maximal
        c = ec.least_free(u)
        F, Fe = [v], [e]
        while not ec.free(F[-1], c):
            last = F[-1]
            nxt = None
            for k in range(D + 1):
                if k in ec.at[u] and ec.free(last, k):
                    x = ec.other(ec.at[u][k], u)
                    if x not in F:
                        nxt = (x, ec.at[u][k])
                        break
            if nxt is None:
                break
            F.append(nxt[0])
            Fe.append(nxt[1])
        if ec.free(F[-1], c):
            d = c
        else:
            d = ec.least_free(F[-1])
            ec.flip_path(u, d, c)
        # least w in F with F[0..w] a fan and d free at w
        wi = None
        for i in range(len(F)):
            if i > 0 and not ec.free(F[i - 1], ec.col[Fe[i]]):
                break
            if ec.free(F[i], d):
                wi = i
                break
        assert wi is not None, "Misra-Gries: no w"
        # rotate F[0..wi]
        cols = [ec.col[Fe[j + 1]] for j in range(wi)]
        for j in range(1, wi + 1):
            ec.unset(Fe[j])
        for j in range(wi):
            ec.set(Fe[j], cols[j])
        ec.set(Fe[wi], d)
        assert max(ec.col[x] for x in range(e + 1)) <= D
    return ec.col


def bipartite_edge_coloring_model(g):
    if any(g.loop) or not is_bip(g.srows):
        return None
    ec = EC(g)
    for e, (a, b) in enumerate(g.ie):
        u, v = (a, b) if a < b else (b, a)
        al = ec.least_free(u)
        be = ec.least_free(v)
        if not ec.free(v, al):
            ec.flip_path(v, al, be)
        ec.set(e, al)
    return ec.col


def proper_edges(g, col):
    for x in range(g.n):
        cs = [col[e] for (_, e) in g.rows[x]]
        # a self-loop appears twice in its row: count it once
        seen = {}
        for (_, e) in g.rows[x]:
            seen[e] = col[e]
        vals = list(seen.values())
        if len(vals) != len(set(vals)):
            return False
    return True


# --------------------------------------------------------------------------------------------
# Rows
# --------------------------------------------------------------------------------------------

def cid():
    return f"CO-{len(CASES)+1:03d}"


def add(group, name, inp, call, expected, checks):
    CASES.append((group, name, inp, call, expected, checks))


def fmt_col(col):
    return f"colors {fmtl(col)}; {ncolors(col)} colors"


def nx_greedy(g, strat):
    try:
        return nx_color_vec(g, nx.greedy_color(g.nx(), strat)) if g.n else []
    except Exception as ex:  # NetworkX smallest_last fails on a self-loop
        return f"raises {type(ex).__name__}"


def case_greedy(name, g, swift, note=None):
    nxname, model = STRATS[swift]
    col = model(g)
    if not proper(g, col):
        fail("greedy colouring not proper")
    checks = []
    nxc = nx_greedy(g, nxname)
    loops = any(g.loop)
    if nxc == col:
        checks.append(f"= NetworkX greedy_color {nxname}")
    else:
        if swift in ("largestFirst", "saturationLargestFirst") and not loops:
            fail(f"{swift} differs from NetworkX: {col} vs {nxc}")
        why = "NetworkX's degree counts the loop twice" if loops else "NetworkX iterates a Python set"
        if isinstance(nxc, str):
            checks.append(f"NetworkX {nxname} {nxc} (a self-loop breaks its degree buckets)")
        else:
            checks.append(f"NetworkX {nxname} gives {fmtl(nxc)} ({why})")
    if swift == "smallestLast":
        o = order_smallest_last(g)
        if not is_smallest_last(g, o):
            fail("not a smallest-last order")
        core = max(nx.core_number(nx.Graph(g.simple_edges())).values(), default=0) if g.simple_edges() else 0
        if ncolors(col) > core + 1:
            fail("smallest last exceeds degeneracy + 1")
        checks.append(f"order {fmtl(o)} is smallest-last; <= degeneracy + 1 = {core + 1}")
    if swift == "saturationLargestFirst":
        checks.append(f"order {fmtl(dsatur_model(g)[1])}")
    if swift == "independentSet":
        _, classes = independent_set_order(g)
        for k, cls in enumerate(classes):
            if any(col[v] != k for v in cls):
                fail("independent set class != colour")
    if swift == "largestFirst" and g.n:
        checks.append(f"order {fmtl(order_largest_first(g))}")
    if note:
        checks.append(note)
    add(f"Greedy.{swift}", name, g.text(), f"greedyColoring(strategy: .{swift})", fmt_col(col), "; ".join(checks))
    return col


def case_order(name, g, order_labels, note=None):
    order = [g.idx[v] for v in order_labels]
    col = first_fit(g, order)
    if not proper(g, col):
        fail("order colouring not proper")
    checks = []
    if g.n:
        nxc = nx_color_vec(g, nx.greedy_color(g.nx(), lambda G_, c: list(order_labels)))
        if nxc != col:
            fail(f"order differs from NetworkX: {col} vs {nxc}")
        checks.append("= NetworkX greedy_color with that order as strategy")
    else:
        checks.append("empty")
    if note:
        checks.append(note)
    add("Greedy.order", name, g.text(), f"greedyColoring(order: {fmtl(order_labels)})", fmt_col(col), "; ".join(checks))


def chi_checks(g, chi):
    checks = []
    if g.n <= 18:
        ie = chi_inclusion_exclusion(g)
        if ie != chi:
            fail(f"chi {chi} vs inclusion-exclusion {ie}")
        checks.append("= inclusion-exclusion count")
    else:
        H = nx.Graph()
        H.add_nodes_from(range(g.n))
        H.add_edges_from(g.simple_edges())
        w = max((len(c) for c in nx.find_cliques(H)), default=0)
        if g.token in LITERATURE_CHI:
            if LITERATURE_CHI[g.token] != chi:
                fail("literature chi")
            checks.append(f"= literature value (clique number {w})")
        elif w == chi:
            checks.append(f"certified by a clique of {w}")
        elif chi == 3 and not nx.is_bipartite(H):
            checks.append("certified: not bipartite, and the colouring has 3")
        else:
            fail(f"no certificate for chi {chi} (clique {w})")
    return checks


def case_chi(name, g, note=None):
    chi = chromatic_number(g)
    checks = chi_checks(g, chi)
    if note:
        checks.append(note)
    add("ChromaticNumber", name, g.text(), "chromaticNumber()", str(chi), "; ".join(checks))


def case_min(name, g, note=None):
    col = minimum_coloring_model(g)
    chi = chromatic_number(g)
    checks = []
    if not proper(g, col) or ncolors(col) != chi:
        fail("minimum colouring wrong count or improper")
    for comp in components(g):
        adj = sub_adj(g, comp)
        k = chi_adj(adj)
        part = [col[v] for v in comp]
        ref = brute_lex_adj(adj, k) if len(comp) <= 12 else plain_lex_adj(adj, k)
        if ref != part:
            fail(f"lex-least mismatch on component {comp}: {part} vs {ref}")
    checks.append("per component = " + ("brute force" if max((len(c) for c in components(g)), default=0) <= 12 else "plain index-order backtracking"))
    checks.extend(chi_checks(g, chi))
    if note:
        checks.append(note)
    add("LexicographicallyFirstMinimumColoring", name, g.text(), "lexicographicallyFirstMinimumColoring()", fmt_col(col), "; ".join(checks))


def restricted_growth_colorings(g, k, limit=2):
    """Up to `limit` proper colour vectors in vertex order with colours < k, each vertex at most one
    above the colours before it (so numbered by first appearance)."""
    adj = sub_adj(g, list(range(g.n)))
    found = []

    def rec(v, col, hi):
        if len(found) >= limit:
            return
        if v == g.n:
            found.append(list(col))
            return
        for c in range(min(k, hi + 2)):
            if all(col[w] != c for w in adj[v] if w < v):
                col.append(c)
                rec(v + 1, col, max(hi, c))
                col.pop()

    rec(0, [], -1)
    return found


def forced_minimum(g):
    """minimumColoring() where the API fixes it: no edges, or bipartite (BipartiteGraphs' sides,
    each component's least vertex 0, which is the lexicographically first colouring), or, on at
    most 12 vertices, a graph with only one chi-colouring numbered by first appearance. Returns
    (colours, why), or (None, None)."""
    if not g.simple_edges():
        return minimum_coloring_model(g), "no edges"
    chi = chromatic_number(g)
    if chi <= 2:
        return minimum_coloring_model(g), "bipartite, the sides"
    if g.n <= 12:
        only = restricted_growth_colorings(g, chi)
        if len(only) == 1:
            if only[0] != minimum_coloring_model(g):
                fail("the only chi-colouring is not the lexicographically first")
            return only[0], "the only χ-colouring numbered by first appearance (exhaustive search)"
    return None, None


def case_any(name, g, note=None):
    chi = chromatic_number(g)
    checks = chi_checks(g, chi)
    forced, why = forced_minimum(g)
    if forced is not None:
        expected = fmt_col(forced)
        checks.insert(0, "forced: " + why)
    else:
        expected = f"{chi} colors, proper, numbered by first appearance"
    if note:
        checks.append(note)
    add("MinimumColoring", name, g.text(), "minimumColoring()", expected, "; ".join(checks))


def rx_graph(g):
    R = rx.PyGraph(multigraph=True)
    R.add_nodes_from(range(g.n))
    R.add_edges_from_no_data([tuple(e) for e in g.ie])
    return R


def case_edge(name, g, note=None):
    if any(g.loop) or g.has_parallel():
        add("EdgeColoring", name, g.text(), "edgeColoring()", "trap", note or "precondition: simple graph")
        return
    col = misra_gries_model(g)
    D = max(g.deg, default=0)
    k = ncolors(col)
    if not proper_edges(g, col) or k > D + 1 or (len(g.ie) and k < D):
        fail("Misra-Gries invalid")
    checks = [f"proper; Delta = {D}, so {D} <= colors <= {D + 1}"]
    if rx is not None and g.ie:
        r = rx.graph_misra_gries_edge_color(rx_graph(g))
        rk = len(set(r.values()))
        rc = [r[e] for e in range(len(g.ie))]
        checks.append("= rustworkx misra_gries_edge_color" if rc == col else f"rustworkx misra_gries uses {rk}")
    if note:
        checks.append(note)
    add("EdgeColoring", name, g.text(), "edgeColoring()", fmt_col(col), "; ".join(checks))


def case_bip_edge(name, g, note=None):
    col = bipartite_edge_coloring_model(g)
    checks = []
    if col is None:
        if not any(g.loop) and nx.is_bipartite(g.nx()):
            fail("bipartite but nil")
        checks.append("not bipartite (NetworkX is_bipartite false)")
        exp = "nil"
    else:
        D = g.max_multi_degree()
        if not proper_edges(g, col) or ncolors(col) != D:
            fail(f"Koenig invalid: {col}, Delta {D}")
        checks.append(f"proper; exactly Delta = {D} colors (Koenig)")
        if rx is not None and g.ie:
            try:
                r = rx.graph_bipartite_edge_color(rx_graph(g))
                checks.append(f"rustworkx bipartite_edge_color uses {len(set(r.values()))}")
            except Exception as ex:  # noqa
                checks.append(f"rustworkx raises {type(ex).__name__}")
        exp = fmt_col(col)
    if note:
        checks.append(note)
    add("BipartiteEdgeColoring", name, g.text(), "bipartiteEdgeColoring()", exp, "; ".join(checks))


def case_is(name, g, colvec, note=None):
    got = proper(g, colvec)
    nxv = nx.coloring.equitable_coloring.is_coloring(g.nx(), dict(zip(g.V, colvec)))
    checks = ["= NetworkX is_coloring" if nxv == got else f"NetworkX is_coloring says {nxv} (it checks self-loops)"]
    if note:
        checks.append(note)
    add("Checks", name, g.text(), f"isVertexColoring {{ {fmtl(colvec)}[$0] }}", str(got).lower(), "; ".join(checks))


def case_is_edge(name, g, colvec, note=None):
    got = proper_edges(g, colvec)
    add("Checks", name, g.text(), f"isEdgeColoring {{ {fmtl(colvec)}[$0] }}", str(got).lower(), note or "definition")


# --------------------------------------------------------------------------------------------
# Catalog
# --------------------------------------------------------------------------------------------

def build():
    E0 = gr([], [])
    one = gr([0], [])
    loop1 = gr([0], [(0, 0)])
    two = gr([0, 1], [])
    edge = gr([0, 1], [(0, 1)])
    par = gr([0, 1, 2], [(0, 1), (1, 0), (1, 2)], kind="multigraph")
    loopy = gr(range(4), [(0, 1), (1, 1), (1, 2), (2, 3), (3, 3), (0, 2)])
    letters = gr(["d", "a", "c", "b"], [("d", "a"), ("a", "c"), ("c", "b"), ("b", "d"), ("d", "c")])
    petersen = named("petersen_graph")

    # ---------------- degenerate inputs, every strategy ----------------
    for sw in STRATS:
        case_greedy("empty graph", E0, sw)
    for sw in STRATS:
        case_greedy("one vertex", one, sw)
    for sw in ["largestFirst", "saturationLargestFirst", "smallestLast"]:
        case_greedy("one vertex with a self-loop: loop ignored", loop1, sw)
    for sw in ["largestFirst", "saturationLargestFirst"]:
        case_greedy("two isolated vertices", two, sw)
        case_greedy("one edge", edge, sw)
        case_greedy("parallel edges count once (degree 1 at 0)", par, sw)
    for sw in ["largestFirst", "saturationLargestFirst", "independentSet", "connectedSequentialBreadthFirst"]:
        case_greedy("self-loops ignored; also in the degree that orders", loopy, sw)

    # ---------------- largest first ----------------
    lf = [("triangle", K(3)), ("K(5)", K(5)), ("path P(5)", P(5)), ("cycle C(5)", C(5)), ("cycle C(6)", C(6)),
          ("star(4): hub first", S(4)), ("wheel(5)", W(5)), ("wheel(6)", W(6)), ("Petersen", petersen),
          ("grid(3,4)", grid(3, 4)), ("Kb(2,3)", Kb(2, 3)), ("crown(4)", crown(4)),
          ("crownx(4): index order pairs the crown, 4 colours", crownx(4)),
          ("vertex order, not label order", letters),
          ("ties: equal degrees keep vertex order", gr(range(6), [(5, 4), (3, 2), (1, 0), (0, 5)])),
          ("nx(bull_graph)", named("bull_graph")), ("nx(house_x_graph)", named("house_x_graph")),
          ("nx(krackhardt_kite_graph)", named("krackhardt_kite_graph")), ("nx(karate_club_graph)", named("karate_club_graph")),
          ("nx(florentine_families_graph): string vertices", named("florentine_families_graph")),
          ("lcg(12,24,1)", lcg(12, 24, 1)), ("lcg(20,50,7)", lcg(20, 50, 7)), ("lcg(30,90,3)", lcg(30, 90, 3))]
    for nm, g in lf:
        case_greedy(nm, g, "largestFirst")

    # ---------------- smallest last ----------------
    sl = [("triangle", K(3)), ("path P(5)", P(5)), ("cycle C(6)", C(6)), ("star(4)", S(4)), ("wheel(5)", W(5)),
          ("Petersen", petersen), ("grid(3,4)", grid(3, 4)), ("crown(4)", crown(4)), ("crownx(4)", crownx(4)),
          ("nx(bull_graph)", named("bull_graph")), ("nx(dodecahedral_graph)", named("dodecahedral_graph")),
          ("nx(karate_club_graph)", named("karate_club_graph")),
          ("lcg(12,24,1)", lcg(12, 24, 1)), ("lcg(20,50,7)", lcg(20, 50, 7)), ("lcg(30,90,3)", lcg(30, 90, 3)),
          ("planar: nx(icosahedral_graph), <= 6 colours", named("icosahedral_graph"))]
    for nm, g in sl:
        case_greedy(nm, g, "smallestLast")

    # ---------------- DSatur ----------------
    ds = [("triangle", K(3)), ("K(5)", K(5)), ("path P(5)", P(5)), ("cycle C(5)", C(5)), ("cycle C(7)", C(7)),
          ("star(4)", S(4)), ("wheel(5)", W(5)), ("wheel(6)", W(6)), ("Petersen", petersen),
          ("grid(3,4)", grid(3, 4)), ("crown(4)", crown(4)),
          ("crownx(5): DSatur is exact on bipartite graphs", crownx(5)),
          ("vertex order, not label order", letters),
          ("nx(bull_graph)", named("bull_graph")), ("nx(house_x_graph)", named("house_x_graph")),
          ("nx(dodecahedral_graph)", named("dodecahedral_graph")), ("nx(chvatal_graph)", named("chvatal_graph")),
          ("nx(mycielski_graph,4): Groetzsch", named("mycielski_graph", 4)),
          ("nx(karate_club_graph)", named("karate_club_graph")),
          ("two components: saturation 0 restarts at the greatest degree", gr(range(7), [(0, 1), (1, 2), (3, 4), (3, 5), (3, 6)])),
          ("lcg(12,24,1)", lcg(12, 24, 1)), ("lcg(20,50,7)", lcg(20, 50, 7)), ("lcg(30,90,3)", lcg(30, 90, 3))]
    for nm, g in ds:
        case_greedy(nm, g, "saturationLargestFirst")

    # ---------------- independent set ----------------
    ind = [("triangle", K(3)), ("path P(5)", P(5)), ("cycle C(5)", C(5)), ("star(4): leaves first", S(4)),
           ("wheel(5)", W(5)), ("Petersen", petersen), ("grid(3,4)", grid(3, 4)), ("crownx(4)", crownx(4)),
           ("nx(bull_graph)", named("bull_graph")), ("nx(karate_club_graph)", named("karate_club_graph")),
           ("lcg(12,24,1)", lcg(12, 24, 1)), ("lcg(20,50,7)", lcg(20, 50, 7))]
    for nm, g in ind:
        case_greedy(nm, g, "independentSet")

    # ---------------- connected sequential ----------------
    cs = [("path P(5)", P(5)), ("cycle C(6)", C(6)), ("star(4)", S(4)), ("Petersen", petersen),
          ("grid(3,4)", grid(3, 4)), ("crownx(4)", crownx(4)),
          ("two components, least vertex roots each", gr(range(7), [(0, 4), (4, 6), (1, 2), (2, 3), (3, 5), (5, 1)])),
          ("component {5, 9}-style: root is the least vertex, not a set's first", gr(range(10), [(9, 5), (0, 1), (1, 2), (2, 3), (3, 4), (6, 7), (7, 8), (8, 6)])),
          ("lcg(12,24,1)", lcg(12, 24, 1)), ("lcg(20,50,7)", lcg(20, 50, 7))]
    for nm, g in cs:
        case_greedy(nm, g, "connectedSequentialBreadthFirst")
        case_greedy(nm, g, "connectedSequentialDepthFirst")

    # ---------------- given order ----------------
    case_order("empty order on the empty graph", E0, [])
    case_order("path in reverse", P(5), [4, 3, 2, 1, 0])
    case_order("crown(4) interleaved: the classic n/2-colour trap", crown(4), [0, 4, 1, 5, 2, 6, 3, 7])
    case_order("crown(4) sides first: 2 colours", crown(4), list(range(8)))
    case_order("labels", letters, ["c", "b", "a", "d"])
    case_order("Petersen, outer then inner", petersen, list(range(10)))
    case_order("Petersen, inner then outer", petersen, list(range(5, 10)) + list(range(5)))
    case_order("self-loop ignored", loopy, [3, 2, 1, 0])
    case_order("parallel edges", par, [2, 1, 0])

    # ---------------- chromatic number ----------------
    chi_rows = [("empty graph: 0", E0), ("one vertex: 1", one), ("self-loop ignored: 1", loop1),
                ("edgeless: 1", two), ("one edge: 2", edge), ("parallel edges: 2", par),
                ("K(1)", K(1)), ("K(4)", K(4)), ("K(7)", K(7)), ("path P(6)", P(6)), ("cycle C(4)", C(4)), ("cycle C(5)", C(5)),
                ("cycle C(9)", C(9)), ("wheel(4): even rim, 3", W(4)), ("wheel(5): odd rim, 4", W(5)),
                ("wheel(8)", W(8)), ("Petersen: 3", petersen), ("nx(mycielski_graph,3): C5", named("mycielski_graph", 3)),
                ("nx(mycielski_graph,4): Groetzsch, triangle-free, 4", named("mycielski_graph", 4)),
                ("nx(mycielski_graph,5): 23 vertices, triangle-free, 5", named("mycielski_graph", 5)),
                ("nx(chvatal_graph): 4", named("chvatal_graph")), ("crown(5): 2", crown(5)), ("crownx(6): 2", crownx(6)),
                ("queen(4)", queen(4)), ("queen(5): 5", queen(5)), ("queen(6): 7", queen(6)),
                ("grid(4,4): 2", grid(4, 4)), ("nx(dodecahedral_graph): 3", named("dodecahedral_graph")),
                ("nx(icosahedral_graph): 4", named("icosahedral_graph")), ("nx(octahedral_graph): 3", named("octahedral_graph")),
                ("nx(heawood_graph): 2", named("heawood_graph")), ("nx(frucht_graph): 3", named("frucht_graph")),
                ("nx(karate_club_graph): 5", named("karate_club_graph")),
                ("components: max over components", gr(range(9), [(0, 1), (1, 2), (2, 0), (3, 4), (5, 6), (6, 7), (7, 8), (8, 5), (5, 7), (6, 8)])),
                ("lcg(14,40,5)", lcg(14, 40, 5)), ("lcg(16,60,9)", lcg(16, 60, 9)), ("lcg(18,70,2)", lcg(18, 70, 2)),
                ("odd cycle with a self-loop: 3", gr(range(5), [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 2)]))]
    for nm, g in chi_rows:
        case_chi(nm, g)

    # ---------------- minimum colouring ----------------
    mins = [("empty graph", E0), ("one vertex", one), ("self-loop ignored", loop1), ("two isolated", two),
            ("one edge", edge), ("parallel edges", par), ("triangle", K(3)), ("K(5): index order", K(5)),
            ("path P(5): bipartition", P(5)), ("cycle C(5)", C(5)), ("cycle C(7)", C(7)), ("wheel(5)", W(5)), ("wheel(6)", W(6)),
            ("Petersen", petersen), ("crownx(4): 2 colours, where first fit needs 4", crownx(4)),
            ("first fit not optimal, so the search decides", gr(range(6), [(0, 2), (2, 3), (3, 1), (1, 4), (4, 5), (5, 0), (2, 5)])),
            ("P4 numbered 0-2-3-1 beside a triangle: each component its own chi", gr(range(7), [(0, 2), (2, 3), (3, 1), (4, 5), (5, 6), (6, 4)])),
            ("vertex order, not label order", letters),
            ("nx(mycielski_graph,4): Groetzsch", named("mycielski_graph", 4)), ("nx(chvatal_graph)", named("chvatal_graph")),
            ("queen(5)", queen(5)), ("nx(dodecahedral_graph)", named("dodecahedral_graph")),
            ("nx(bull_graph)", named("bull_graph")), ("nx(house_x_graph)", named("house_x_graph")),
            ("lcg(12,24,1)", lcg(12, 24, 1)), ("lcg(14,40,5)", lcg(14, 40, 5)), ("lcg(16,60,9)", lcg(16, 60, 9)),
            ("self-loops ignored in a bigger graph", loopy)]
    for nm, g in mins:
        case_min(nm, g)
    MINS[:] = mins

    # ---------------- edge colouring (Misra-Gries) ----------------
    eds = [("empty graph", E0), ("one vertex", one), ("one edge", edge), ("path P(5): Delta 2", P(5)),
           ("triangle: class 2, Delta + 1", K(3)), ("K(4): class 1", K(4)), ("K(5): class 2", K(5)),
           ("cycle C(5): odd, 3", C(5)), ("cycle C(6)", C(6)), ("star(5): Delta", S(5)), ("wheel(5)", W(5)),
           ("Petersen: class 2, 4 colours", petersen), ("grid(3,4)", grid(3, 4)), ("Kb(3,3)", Kb(3, 3)),
           ("nx(dodecahedral_graph)", named("dodecahedral_graph")), ("nx(karate_club_graph)", named("karate_club_graph")),
           ("edge order matters: C(4) listed 0-1, 2-3, 1-2, 3-0", gr(range(4), [(0, 1), (2, 3), (1, 2), (3, 0)])),
           ("lcg(12,24,1)", lcg(12, 24, 1)), ("lcg(20,50,7)", lcg(20, 50, 7)), ("lcg(30,90,3)", lcg(30, 90, 3)),
           ("self-loop", loop1), ("parallel edges", par)]
    for nm, g in eds:
        case_edge(nm, g)

    # ---------------- bipartite edge colouring ----------------
    beds = [("empty graph", E0), ("one edge", edge), ("path P(6)", P(6)), ("cycle C(6)", C(6)),
            ("Kb(3,3): Latin square", Kb(3, 3)), ("Kb(2,4)", Kb(2, 4)), ("crown(4)", crown(4)),
            ("grid(3,4)", grid(3, 4)), ("nx(heawood_graph)", named("heawood_graph")),
            ("bipartite multigraph: parallel edges need different colours", gr([0, 1, 2], [(0, 1), (0, 1), (1, 2), (0, 1)], kind="multigraph")),
            ("lcgb(6,6,20,4)", lcgb(6, 6, 20, 4)), ("lcgb(8,5,30,11)", lcgb(8, 5, 30, 11)),
            ("triangle: nil", K(3)), ("self-loop: nil", gr([0, 1], [(0, 1), (1, 1)])), ("Petersen: nil", petersen)]
    for nm, g in beds:
        case_bip_edge(nm, g)

    # ---------------- checks ----------------
    case_is("empty colouring of the empty graph", E0, [])
    case_is("one colour on an edge", edge, [0, 0])
    case_is("two colours on an edge", edge, [0, 1])
    case_is("self-loop ignored", loop1, [0])
    case_is("self-loop ignored with a proper rest", loopy, [0, 1, 2, 0])
    case_is("parallel edges", par, [0, 1, 0])
    case_is("triangle with a repeat", K(3), [0, 1, 1])
    case_is("colours need not be 0..<k or contiguous", P(3), [7, -2, 7])
    case_is("Petersen, a greedy colouring", petersen, first_fit(petersen, range(10)))
    case_is_edge("empty", E0, [])
    case_is_edge("path, alternating", P(4), [0, 1, 0])
    case_is_edge("path, repeat at a shared end", P(4), [0, 0, 1])
    case_is_edge("parallel edges share both ends", par, [0, 0, 1])
    case_is_edge("parallel edges, distinct", par, [0, 1, 2])
    case_is_edge("a self-loop meets the other edges at its vertex", gr([0, 1], [(0, 0), (0, 1)]), [0, 0])
    case_is_edge("a self-loop alone", loop1, [0])

    # ---------------- traps ----------------
    add("Trap", "order misses a vertex", P(3).text(), "greedyColoring(order: [0, 1])", "trap", "precondition: every vertex exactly once (NetworkX KeyError later, Boost undefined)")
    add("Trap", "order repeats a vertex", P(3).text(), "greedyColoring(order: [0, 1, 1, 2])", "trap", "precondition")
    add("Trap", "order names a non-vertex", P(3).text(), "greedyColoring(order: [0, 1, 2, 3])", "trap", "precondition")
    add("Trap", "color(of:) a non-vertex", P(3).text(), "greedyColoring().color(of: 9)", "trap", "precondition")
    add("Trap", "color(ofIndex:) out of range", P(3).text(), "greedyColoring().color(ofIndex: 3)", "trap", "precondition: index in 0..<vertexCount")


MINS = []


def build_tail():
    t = lcgb(8, 5, 30, 11)
    case_edge("lcgb(8,5,30,11): Delta + 1 on a bipartite graph (bipartiteEdgeColoring gives Delta, CO-228)",
              G(t.V, t.E, token=t.token))
    # minimumColoring() on the lexicographically first rows' graphs (CO-167 – CO-194).
    for nm, g in MINS:
        case_any(nm, g)


# --------------------------------------------------------------------------------------------
# Stress
# --------------------------------------------------------------------------------------------

def stress():
    rnd = random.Random(20261009)
    count = 0
    agree = {k: 0 for k in STRATS}
    for t in range(1500):
        n = rnd.randint(0, 9)
        p = rnd.random()
        E = [(u, v) for u in range(n) for v in range(u + 1, n) if rnd.random() < p]
        rnd.shuffle(E)
        E = [(v, u) if rnd.random() < 0.5 else (u, v) for (u, v) in E]
        g = G(range(n), E)
        for sw, (nxname, model) in STRATS.items():
            col = model(g)
            if not proper(g, col):
                FAILS.append(f"stress {t}: {sw} improper")
            nxc = nx_greedy(g, nxname)
            if col == nxc:
                agree[sw] += 1
            elif sw in ("largestFirst", "saturationLargestFirst"):
                FAILS.append(f"stress {t}: {sw} vs NetworkX on {g.text()}: {col} vs {nxc}")
        if not is_smallest_last(g, order_smallest_last(g)):
            FAILS.append(f"stress {t}: smallest last")
        chi = chromatic_number(g)
        if chi != chi_inclusion_exclusion(g):
            FAILS.append(f"stress {t}: chi")
        mc = minimum_coloring_model(g)
        for comp in components(g):
            adj = sub_adj(g, comp)
            if [mc[v] for v in comp] != brute_lex_adj(adj, chi_adj(adj)):
                FAILS.append(f"stress {t}: lex least")
        if any(ncolors(model(g)) < chi for (_, model) in STRATS.values()):
            FAILS.append(f"stress {t}: greedy below chi")
        ec = misra_gries_model(g)
        D = max(g.deg, default=0)
        if not proper_edges(g, ec) or ncolors(ec) > D + 1:
            FAILS.append(f"stress {t}: Misra-Gries")
        b = bipartite_edge_coloring_model(g)
        if (b is None) == nx.is_bipartite(g.nx()):
            FAILS.append(f"stress {t}: bipartite edge nil")
        if b is not None and (not proper_edges(g, b) or ncolors(b) != D):
            FAILS.append(f"stress {t}: Koenig count")
        count += 1
    # bipartite multigraphs for Koenig
    for t in range(300):
        l, r = rnd.randint(1, 5), rnd.randint(1, 5)
        E = [(rnd.randrange(l), l + rnd.randrange(r)) for _ in range(rnd.randint(0, 14))]
        g = G(range(l + r), E, kind="multigraph")
        b = bipartite_edge_coloring_model(g)
        if b is None or not proper_edges(g, b) or ncolors(b) != g.max_multi_degree():
            FAILS.append(f"stress multigraph {t}: Koenig")
    print(f"stress: {count} random graphs + 300 bipartite multigraphs pass; NetworkX agreement per strategy: "
          + ", ".join(f"{k} {v}/{count}" for k, v in agree.items()))


HEADER = """# ColoringModule: case catalog (CO-001 – CO-{last}, {count} cases)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
rustworkx python3 ref.py`; `--write` regenerates this file, `--stress` adds 1,500 random graphs and
300 bipartite multigraphs). Expected is the API's documented output (api.md, Determinism); the last
column says what each row was checked against.

## Notation

* **Graphs.** `V [..]; E [..]`: vertices in order (their vertex indices), then edges at positions
  0, 1, …, each `u-v`. Rows list edge ends in position order (an `UndirectedAdjacencyList` built
  by inserting `E` in order; a self-loop twice). `multigraph` rows have parallel edges (tests need
  an in-file `Graph` conformer). `L [..]; R [..]; E [..]` is a `BipartiteGraph(left:right:edges:)`.
* **Generators.** `K(n)` every pair i < j lexicographic; `C(n)` edges i–(i+1) mod n; `P(n)` the
  path; `star(k)` hub 0, edges 0–i; `wheel(k)` hub 0, spokes 0–i then rim i–(i mod k + 1);
  `Kb(a,b)` the `BipartiteGraph` with left 0..<a, right a..<a+b, edges row-major; `crown(k)`:
  `Kb(k,k)` without the edges i–(k+i), row-major, as a `BipartiteGraph`; `crownx(k)`: the crown
  numbered u_i = 2i, w_i = 2i+1, edges 2i–(2j+1) for i ≠ j row-major, an
  `UndirectedAdjacencyList`; `grid(r,c)` vertex i·c+j, edges right then down, row-major;
  `queen(n)`: square i·n+j, an edge between squares on one row, column or diagonal, pairs a < b
  lexicographic; `nx(name[,arg])` NetworkX's `name(arg)` nodes and `edges()` in order.
  `lcg(n,m,seed)`: a 64-bit LCG, x ← x·6364136223846793005 + 1442695040888963407 (mod 2⁶⁴), each
  draw x >> 33; an edge is two draws (u = d % n, v = d % n), skipped when u = v or the pair is
  already an edge, until m edges. `lcgb(l,r,m,seed)`: a `BipartiteGraph`, left 0..<l, right
  l..<l+r, an edge u = d % l, v = l + d % r, repeats skipped.
* **Colourings.** `colors [..]; k colors`: the colour of each vertex in `vertices` order
  (`coloring.color(of:)`), then `colorCount`. Colour classes follow: class c is the vertices of
  colour c in `vertices` order. Edge colourings list the colour of each edge in position order.
* **Orders** in the Checked column are vertex indices.
* **trap** rows are preconditions: tests run them as exit tests (`#expect(processExitsWith:)`).
* **`minimumColoring()`** rows (after CO-253) repeat the graphs of CO-167 – CO-194. Its colouring
  is whichever optimal one the exact search finds, renumbered by first appearance, so Expected
  gives the colours only where they are forced (no edges; bipartite, the sides; or the only
  χ-colouring so numbered, by exhaustive search on at most 12 vertices), and otherwise
  χ and the rule: proper, χ colours, the first vertex colour 0 and each colour first used after
  the one below it.

| ID | Group | Case | Input | Call | Expected | Checked |
|---|---|---|---|---|---|---|
"""


def main():
    if "--stress" in sys.argv:
        stress()
    build()
    build_tail()
    if FAILS:
        print("\n".join(FAILS))
        sys.exit(1)
    if "--write" in sys.argv:
        out = HEADER.replace("{last}", f"{len(CASES):03d}").replace("{count}", str(len(CASES)))
        for i, (grp, name, inp, call, exp, chk) in enumerate(CASES):
            out += f"| CO-{i+1:03d} | {grp} | {name} | {inp} | `{call}` | {exp} | {chk} |\n"
        open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cases.md"), "w").write(out)
    print(f"{len(CASES)} cases; all values agree" + ("" if rx else " (rustworkx not installed: its notes skipped)"))


if __name__ == "__main__":
    main()
