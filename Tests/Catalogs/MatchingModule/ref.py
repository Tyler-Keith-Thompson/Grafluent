"""MatchingModule phase 1: reference model and independent checks for every catalog row.

Run:  uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3 ref.py
      (add --write to regenerate cases.md)

What decides Expected, per entry point (api.md, Determinism):

* maximalMatching()                 model: greedy in position order. Checked: equal to NetworkX
                                    maximal_matching (simple graphs), maximal, valid.
* isMatching / isMaximalMatching /  model: definitions. Checked: NetworkX is_matching,
  isPerfectMatching                 is_maximal_matching, is_perfect_matching (simple graphs).
* maximumBipartiteMatching()        model: Hopcroft-Karp exactly as NetworkX hopcroft_karp_matching
                                    (Wikipedia pseudocode), left in `left` order, rows in
                                    incidentEdges order. Checked: equal to NetworkX's output whenever
                                    NetworkX iterates its left set in the same order (it iterates a
                                    Python set), else equal size; size equal to a brute-force maximum;
                                    the König cover (alternating search from free left vertices) equal
                                    to NetworkX to_vertex_cover and of the same size as the matching.
* maximumMatching()                 model: Edmonds' blossom, roots in vertex order, breadth-first,
                                    union-find bases (api.md). Checked: valid; size equal to NetworkX
                                    max_weight_matching(maxcardinality=True) with unit weights and to
                                    a brute-force maximum (small graphs).
* maximumWeightMatching()           model = NetworkX 3.7 max_weight_matching run on the simple graph
                                    (parallel copies collapsed to the heaviest, earliest on ties;
                                    vertices in order; edges in position order). Checked: weight (and
                                    cardinality with maximumCardinality) equal to a brute force.
* minimumWeightMatching()           model = the above with weights (1 + max) - w, maximumCardinality.
                                    Checked: weight and cardinality equal to NetworkX
                                    min_weight_matching and to a brute force.
* minimumWeightFullMatching()       model = scipy linear_sum_assignment on the |L| x |R| biadjacency
                                    matrix (rows in `left` order, +inf where no edge), nil when scipy
                                    reports infeasible. Checked: our Python port of scipy's
                                    rectangular_lsap (the algorithm the Swift code ports) gives the
                                    same assignment; weight equal to NetworkX
                                    minimum_weight_full_matching and to a brute force.
* linearSumAssignment()             model = scipy linear_sum_assignment (nil entries = +inf).
                                    Checked: the port agrees exactly; cost equal to a brute force over
                                    all assignments. Where scipy's float64 rounds an integer matrix,
                                    Expected is the exact port run on Python ints, checked by brute
                                    force (MA rows note it).
* stableMatching()                  model: proposer-proposing deferred acceptance. Checked: stable,
                                    and proposer-optimal and rural-hospitals against every stable
                                    matching enumerated by brute force.
"""
import itertools
import math
import os
import sys
from collections import deque

import networkx as nx
import numpy as np
import scipy
import scipy.optimize

assert nx.__version__ == "3.7" and scipy.__version__ == "1.18.1"

INF = float("inf")
CASES = []
FAILS = []


def fail(cid, msg):
    FAILS.append(f"{cid}: {msg}")


# --------------------------------------------------------------------------------------------
# Graph notation
# --------------------------------------------------------------------------------------------

class G:
    """An undirected graph as the API sees it: vertices in order, edges at positions 0.."""

    def __init__(self, V, E, kind="graph", left=None, right=None, token=None):
        self.V = list(V)
        self.E = [tuple(e) if len(e) == 3 else (e[0], e[1], None) for e in E]
        self.kind = kind          # graph | multigraph | bipartite
        self.left = left
        self.right = right
        self.token = token
        self.idx = {v: i for i, v in enumerate(self.V)}
        for (u, v, _) in self.E:
            assert u in self.idx and v in self.idx, (u, v)
        pairs = [frozenset((u, v)) for (u, v, _) in self.E]
        if kind != "multigraph":
            assert len(set(pairs)) == len(pairs), "parallel edges need kind=multigraph"
        self.n = len(self.V)
        self.rows = [[] for _ in self.V]
        for e, (u, v, _) in enumerate(self.E):
            a, b = self.idx[u], self.idx[v]
            self.rows[a].append((b, e))
            self.rows[b].append((a, e))   # a self-loop is listed twice

    def w(self, e):
        x = self.E[e][2]
        return 1 if x is None else x

    def text(self):
        def es():
            out = []
            for (u, v, w) in self.E:
                s = f"{u}-{v}"
                if w is not None:
                    s += f":{fmtw(w)}"
                out.append(s)
            return ", ".join(out)
        if self.token:
            return self.token
        if self.kind == "bipartite":
            return f"L {fmtl(self.left)}; R {fmtl(self.right)}; E [{es()}]"
        tag = "multigraph " if self.kind == "multigraph" else ""
        return f"{tag}V {fmtl(self.V)}; E [{es()}]"

    def nx_simple(self, weighted=True):
        """NetworkX graph: vertices in order, then the collapsed edges in first-appearance order.
        Returns (graph, chosen) with chosen[frozenset pair] = position of the copy kept."""
        H = nx.Graph()
        H.add_nodes_from(self.V)
        best = {}
        order = []
        for e, (u, v, _) in enumerate(self.E):
            if u == v:
                continue
            k = frozenset((u, v))
            if k not in best:
                best[k] = e
                order.append(k)
            elif self.w(e) > self.w(best[k]):
                best[k] = e
        for k in order:
            e = best[k]
            u, v, _ = self.E[e]
            if weighted:
                H.add_edge(u, v, weight=self.w(e))
            else:
                H.add_edge(u, v)
        return H, best


def fmtw(w):
    if isinstance(w, float):
        if w == INF:
            return "inf"
        r = repr(w)
        return r
    return str(w)


def fmtl(xs):
    return "[" + ", ".join(str(x) for x in xs) + "]"


class LCG:
    """64-bit LCG (Knuth MMIX constants); next() returns the high 31 bits."""

    def __init__(self, seed):
        self.x = seed & (2**64 - 1)

    def next(self):
        self.x = (self.x * 6364136223846793005 + 1442695040888963407) % 2**64
        return self.x >> 33


def lcg_graph(n, m, seed, wmax=None):
    r = LCG(seed)
    seen = set()
    E = []
    while len(E) < m:
        u, v = r.next() % n, r.next() % n
        if u == v or frozenset((u, v)) in seen:
            continue
        seen.add(frozenset((u, v)))
        if wmax is None:
            E.append((u, v, None))
        else:
            E.append((u, v, 1 + r.next() % wmax))
    tok = f"lcg({n},{m},{seed})" if wmax is None else f"lcgw({n},{m},{seed},{wmax})"
    return G(range(n), E, token=tok)


def lcg_bipartite(l, rr, m, seed, wmax=None):
    r = LCG(seed)
    seen = set()
    E = []
    assert m <= l * rr
    while len(E) < m:
        u, v = r.next() % l, l + r.next() % rr
        if (u, v) in seen:
            continue
        seen.add((u, v))
        E.append((u, v, None if wmax is None else 1 + r.next() % wmax))
    tok = (f"lcgb({l},{rr},{m},{seed})" if wmax is None else f"lcgbw({l},{rr},{m},{seed},{wmax})")
    return G(list(range(l + rr)), E, kind="bipartite", left=list(range(l)),
             right=list(range(l, l + rr)), token=tok)


def K(n):
    return G(range(n), [(i, j) for i in range(n) for j in range(i + 1, n)], token=f"K({n})")


def C(n):
    return G(range(n), [(i, (i + 1) % n) for i in range(n)], token=f"C({n})")


def P(n):
    return G(range(n), [(i, i + 1) for i in range(n - 1)], token=f"P({n})")


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


def petersen():
    H = nx.petersen_graph()
    return G(list(H.nodes), list(H.edges), token="nx(petersen)")


def bip(L, R, E):
    return G(list(L) + list(R), E, kind="bipartite", left=list(L), right=list(R))


# --------------------------------------------------------------------------------------------
# Models
# --------------------------------------------------------------------------------------------

def is_matching(g, es):
    seen = set()
    if len(set(es)) != len(es):
        return False
    for e in es:
        u, v, _ = g.E[e]
        if u == v or u in seen or v in seen:
            return False
        seen.add(u)
        seen.add(v)
    return True


def is_maximal(g, es):
    if not is_matching(g, es):
        return False
    cov = set()
    for e in es:
        cov.update(g.E[e][:2])
    return not any(u != v and u not in cov and v not in cov for (u, v, _) in g.E)


def is_perfect(g, es):
    return is_matching(g, es) and 2 * len(es) == g.n


def maximal_model(g):
    cov = set()
    out = []
    for e, (u, v, _) in enumerate(g.E):
        if u != v and u not in cov and v not in cov:
            out.append(e)
            cov.update((u, v))
    return out


def hk_model(g, left_order):
    """NetworkX hopcroft_karp_matching on index rows, with an explicit left order."""
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

    phases = 0
    while bfs():
        phases += 1
        for v in left:
            if pairL[v] is None:
                dfs(v)
    out = sorted(edgeL[v] for v in left if pairL[v] is not None)
    for v in left:
        if pairL[v] is not None:
            assert pairR[pairL[v]] == v
    return out, phases


def konig_cover(g, left_order, es):
    """Z = vertices reached by alternating paths from free left vertices; cover (L-Z) + (R&Z)."""
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
    cover = [v for v in range(g.n) if (v in left and v not in Z) or (v not in left and v in Z)]
    return [g.V[v] for v in cover]


def edmonds_model(g):
    """Edmonds' blossom algorithm as api.md documents it (union-find bases, BFS per free root)."""
    n = g.n
    mate = [-1] * n
    mateE = [-1] * n
    for r in range(n):
        if mate[r] != -1:
            continue
        label = [0] * n           # 0 unlabeled, 1 even, 2 odd
        link = [-1] * n
        linkE = [-1] * n
        uf = list(range(n))
        vis = [False] * n         # lca marks

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
    out = sorted(set(mateE[v] for v in range(n) if mate[v] != -1))
    for v in range(n):
        if mate[v] != -1:
            assert mate[mate[v]] == v
    return out


def nx_pairs_to_pos(g, chosen, pairs):
    return sorted(chosen[frozenset(p)] for p in pairs)


def mwm_model(g, maxcard):
    H, chosen = g.nx_simple()
    pairs = nx.max_weight_matching(H, maxcardinality=maxcard)
    return nx_pairs_to_pos(g, chosen, pairs)


def minwm_model(g):
    H, chosen = g.nx_simple()
    if H.number_of_edges() == 0:
        return []
    ws = [d["weight"] for _, _, d in H.edges(data=True)]
    one = 1.0 if any(isinstance(x, float) for x in ws) else 1
    c = one + max(ws)
    H2 = nx.Graph()
    H2.add_nodes_from(H.nodes)
    for u, v, d in H.edges(data=True):
        H2.add_edge(u, v, weight=c - d["weight"])
    pairs = nx.max_weight_matching(H2, maxcardinality=True)
    return nx_pairs_to_pos(g, chosen, pairs)


def lsap_port(cost, maximize=False):
    """Port of scipy's rectangular_lsap.cpp (Crouse 2016). cost: list of rows, None = forbidden.
    Exact on Python ints. Returns (rows, cols) or None when infeasible."""
    nr = len(cost)
    nc = len(cost[0]) if nr else 0
    if nr == 0 or nc == 0:
        return [], []
    transpose = nc < nr
    c = [row[:] for row in cost]
    if transpose:
        c = [[cost[i][j] for i in range(nr)] for j in range(nc)]
        nr, nc = nc, nr
    if maximize:
        c = [[None if x is None else -x for x in row] for row in c]
    u = [0] * nr
    v = [0] * nc
    spc = [None] * nc       # None = +inf
    path = [-1] * nc
    col4row = [-1] * nr
    row4col = [-1] * nc
    for cur in range(nr):
        minVal = 0
        remaining = [nc - it - 1 for it in range(nc)]
        num = nc
        SR = [False] * nr
        SC = [False] * nc
        spc = [None] * nc
        i = cur
        sink = -1
        while sink == -1:
            index = -1
            lowest = None
            SR[i] = True
            for it in range(num):
                j = remaining[it]
                if c[i][j] is not None:
                    r = minVal + c[i][j] - u[i] - v[j]
                    if spc[j] is None or r < spc[j]:
                        path[j] = i
                        spc[j] = r
                s = spc[j]
                if lowest is None:
                    lt = s is not None
                    eq = s is None
                else:
                    lt = s is not None and s < lowest
                    eq = s is not None and s == lowest
                if index == -1 or lt or (eq and row4col[j] == -1):
                    lowest = s
                    index = it
            minVal = lowest
            if minVal is None:
                return None
            j = remaining[index]
            if row4col[j] == -1:
                sink = j
            else:
                i = row4col[j]
            SC[j] = True
            num -= 1
            remaining[index] = remaining[num]
        u[cur] += minVal
        for i2 in range(nr):
            if SR[i2] and i2 != cur:
                u[i2] += minVal - spc[col4row[i2]]
        for j2 in range(nc):
            if SC[j2]:
                v[j2] -= minVal - spc[j2]
        j = sink
        while True:
            i2 = path[j]
            row4col[j] = i2
            col4row[i2], j = j, col4row[i2]
            if i2 == cur:
                break
    if transpose:
        order = sorted(range(nr), key=lambda k: col4row[k])
        return [col4row[k] for k in order], list(order)
    return list(range(nr)), col4row[:]


def scipy_lsa(cost, maximize=False):
    nr = len(cost)
    nc = len(cost[0]) if nr else 0
    # scipy cannot mark a forbidden entry under maximize (it negates, and -inf is invalid), so
    # forbidden entries with maximize go through its own reduction: negate, then minimize.
    neg = maximize and any(x is None for row in cost for x in row)
    a = np.array([[INF if x is None else (-x if neg else x) for x in row] for row in cost], dtype=float).reshape(nr, nc)
    try:
        r, c = scipy.optimize.linear_sum_assignment(a, maximize=maximize and not neg)
    except ValueError as e:
        if "infeasible" in str(e):
            return None
        raise
    return [int(x) for x in r], [int(x) for x in c]


def biadjacency(g, rows_order, cols_order):
    ri = {v: k for k, v in enumerate(rows_order)}
    ci = {v: k for k, v in enumerate(cols_order)}
    M = [[None] * len(cols_order) for _ in rows_order]
    pos = [[None] * len(cols_order) for _ in rows_order]
    for e, (u, v, _) in enumerate(g.E):
        if u in ri and v in ci:
            a, b = ri[u], ci[v]
        elif v in ri and u in ci:
            a, b = ri[v], ci[u]
        else:
            raise AssertionError("edge inside a side")
        if M[a][b] is None or g.w(e) < M[a][b]:
            M[a][b] = g.w(e)
            pos[a][b] = e
    return M, pos


def mwfm_model(g, left, right):
    M, pos = biadjacency(g, left, right)
    res = scipy_lsa(M)
    port = lsap_port(M)
    return res, port, pos


def stable_model(pp, rp):
    P, R = len(pp), len(rp)
    rank = [dict() for _ in range(R)]
    for r in range(R):
        for k, p in enumerate(rp[r]):
            rank[r][p] = k
    nxt = [0] * P
    held = [None] * R
    q = deque(range(P))
    while q:
        p = q.popleft()
        while nxt[p] < len(pp[p]):
            r = pp[p][nxt[p]]
            nxt[p] += 1
            if p not in rank[r]:
                continue
            cur = held[r]
            if cur is None:
                held[r] = p
                break
            if rank[r][p] < rank[r][cur]:
                held[r] = p
                q.append(cur)
                break
    mate = [None] * P
    for r in range(R):
        if held[r] is not None:
            mate[held[r]] = r
    return mate


def stable_check(cid, pp, rp, mate):
    P, R = len(pp), len(rp)
    prank = [{r: k for k, r in enumerate(pp[p])} for p in range(P)]
    rrank = [{p: k for k, p in enumerate(rp[r])} for r in range(R)]
    acc = [(p, r) for p in range(P) for r in range(R) if r in prank[p] and p in rrank[r]]

    def stable(m):
        rm = {r: p for p, r in enumerate(m) if r is not None}
        for (p, r) in acc:
            if m[p] == r:
                continue
            pbetter = m[p] is None or prank[p][r] < prank[p][m[p]]
            rbetter = r not in rm or rrank[r][p] < rrank[r][rm[r]]
            if pbetter and rbetter:
                return False
        return True

    if not stable(mate):
        fail(cid, "not stable")
    for p, r in enumerate(mate):
        if r is not None and (p, r) not in acc:
            fail(cid, "unacceptable pair")
    if P * R > 64 and len(acc) > 22:
        return "stable (enumeration skipped)"
    # enumerate all matchings over acceptable pairs
    allstable = []

    def rec(p, used, m):
        if p == P:
            if stable(m):
                allstable.append(list(m))
            return
        m.append(None)
        rec(p + 1, used, m)
        m.pop()
        for r in pp[p]:
            if (p, r) in set(acc) and r not in used:
                used.add(r)
                m.append(r)
                rec(p + 1, used, m)
                m.pop()
                used.discard(r)

    rec(0, set(), [])
    for s in allstable:
        for p in range(P):
            if s[p] is not None and (mate[p] is None or prank[p][s[p]] < prank[p][mate[p]]):
                fail(cid, "not proposer-optimal")
        if set(p for p in range(P) if s[p] is not None) != set(p for p in range(P) if mate[p] is not None):
            fail(cid, "rural hospitals violated")
    return f"stable; proposer-optimal among {len(allstable)} stable matchings"


# --------------------------------------------------------------------------------------------
# Brute force
# --------------------------------------------------------------------------------------------

def brute(g, key):
    """Best matching by key(card, weight) over all matchings (small graphs)."""
    n = g.n
    adj = [[] for _ in range(n)]
    for e, (u, v, _) in enumerate(g.E):
        a, b = g.idx[u], g.idx[v]
        if a != b:
            adj[a].append((b, e))
            adj[b].append((a, e))
    best = [None]
    used = [False] * n

    def rec(v, card, wt):
        while v < n and used[v]:
            v += 1
        if v == n:
            k = key(card, wt)
            if best[0] is None or k > best[0][0]:
                best[0] = (k, card, wt)
            return
        used[v] = True
        rec(v + 1, card, wt)
        for (b, e) in adj[v]:
            if not used[b]:
                used[b] = True
                rec(v + 1, card + 1, wt + g.w(e))
                used[b] = False
        used[v] = False

    rec(0, 0, 0)
    return best[0][1], best[0][2]


def small(g):
    return g.n <= 16 and len(g.E) <= 40


def weight_of(g, es):
    t = 0
    for e in es:
        t = t + g.w(e)
    return t


def close(a, b):
    if isinstance(a, float) or isinstance(b, float):
        return abs(a - b) <= 1e-9 * max(1.0, abs(a), abs(b))
    return a == b


# --------------------------------------------------------------------------------------------
# Formatting
# --------------------------------------------------------------------------------------------

def fmt_matching(g, es, weight=None, show_weight=False):
    pairs = ", ".join(f"{g.E[e][0]}–{g.E[e][1]}" for e in es)
    s = f"edges {fmtl(es)} {{{pairs}}}"
    if show_weight:
        s += f"; weight {fmtw(weight)}"
    if 2 * len(es) == g.n:
        s += "; perfect"
    return s


def add(cid_group, name, inp, call, expected, checks, notes=""):
    CASES.append((cid_group, name, inp, call, expected, checks, notes))


# --------------------------------------------------------------------------------------------
# Case builders
# --------------------------------------------------------------------------------------------

def case_maximal(name, g, notes=""):
    cid = f"MA-{len(CASES)+1:03d}"
    es = maximal_model(g)
    assert is_maximal(g, es)
    chk = "maximal; valid"
    if g.kind != "multigraph":
        H, chosen = g.nx_simple(weighted=False)
        nm = nx.maximal_matching(H)
        got = sorted(chosen[frozenset(p)] for p in nm)
        same_order = [chosen[frozenset(p)] for p in H.edges()] == sorted(chosen.values())
        if got == es:
            chk = "= NetworkX maximal_matching"
        elif not same_order:
            chk = "maximal; valid; NetworkX scans G.edges() (by node, then neighbour), a different order, and returns " + fmtl(got)
        else:
            fail(cid, f"maximal differs from NetworkX {got} vs {es}")
    add("Maximal", name, g.text(), "maximalMatching()", fmt_matching(g, es), chk, notes)


def case_check(name, g, es, notes=""):
    cid = f"MA-{len(CASES)+1:03d}"
    a, b, c = is_matching(g, es), is_maximal(g, es), is_perfect(g, es)
    chk = "definitions"
    if g.kind != "multigraph" and len(set(es)) == len(es):
        H = nx.Graph()
        H.add_nodes_from(g.V)
        H.add_edges_from((u, v) for (u, v, _) in g.E)
        pairs = {(g.E[e][0], g.E[e][1]) for e in es}
        na, nb, nc = nx.is_matching(H, pairs), nx.is_maximal_matching(H, pairs), nx.is_perfect_matching(H, pairs)
        if (na, nb, nc) != (a, b, c):
            fail(cid, f"checks differ from NetworkX {(na, nb, nc)} vs {(a, b, c)}")
        chk = "= NetworkX is_matching, is_maximal_matching, is_perfect_matching"
    add("Checks", name, g.text(), f"isMatching / isMaximalMatching / isPerfectMatching({fmtl(es)})",
        f"{str(a).lower()} / {str(b).lower()} / {str(c).lower()}", chk, notes)


def case_hk(name, g, left=None, notes="", via="bipartite"):
    cid = f"MA-{len(CASES)+1:03d}"
    if left is None:
        if g.kind == "bipartite":
            left = g.left
        else:
            H = nx.Graph()
            H.add_nodes_from(g.V)
            H.add_edges_from((u, v) for (u, v, _) in g.E)
            # canonical bipartition: least vertex of each component left, BFS 2-colouring
            side = {}
            for s in g.V:
                if s in side:
                    continue
                side[s] = 0
                q = deque([s])
                while q:
                    x = q.popleft()
                    for (y, _) in g.rows[g.idx[x]]:
                        yv = g.V[y]
                        if yv not in side:
                            side[yv] = 1 - side[x]
                            q.append(yv)
            left = [v for v in g.V if side[v] == 0]
    es, phases = hk_model(g, left)
    assert is_matching(g, es)
    cover = konig_cover(g, left, es)
    if len(cover) != len(es):
        fail(cid, "König cover size differs from matching size")
    for (u, v, _) in g.E:
        if u not in cover and v not in cover:
            fail(cid, "cover misses an edge")
    chk = []
    if small(g):
        card, _ = brute(g, lambda c, w: c)
        if card != len(es):
            fail(cid, "HK not maximum")
        chk.append("size = brute force")
    if g.kind != "multigraph":
        H, chosen = g.nx_simple(weighted=False)
        top = set(left)
        nxm = nx.bipartite.hopcroft_karp_matching(H, top_nodes=top)
        nxpairs = {frozenset((a, b)) for a, b in nxm.items()}
        if len(nxpairs) != len(es):
            fail(cid, "size differs from NetworkX")
        X = set(top)
        if list(X) == list(left):
            got = sorted(chosen[p] for p in nxpairs)
            if got != es:
                fail(cid, f"HK differs from NetworkX with same order {got} vs {es}")
            chk.append("= NetworkX hopcroft_karp_matching")
            nxc = nx.bipartite.to_vertex_cover(H, nxm, top_nodes=top)
            if set(nxc) != set(cover):
                fail(cid, f"cover differs from NetworkX to_vertex_cover {nxc} vs {cover}")
            chk.append("cover = NetworkX to_vertex_cover")
        else:
            chk.append("size = NetworkX hopcroft_karp_matching (its left-set order differs)")
    call = "maximumBipartiteMatching()" if via == "bipartite" else "maximumBipartiteMatching(bipartition: bipartition()!)"
    exp = fmt_matching(g, es) + f"; König cover {fmtl(cover)}; {phases} phase" + ("s" if phases != 1 else "")
    if via != "bipartite":
        exp = f"left {fmtl(left)}; " + exp
    add("Hopcroft–Karp", name, g.text(), call, exp, "; ".join(chk), notes)


def case_edmonds(name, g, notes=""):
    cid = f"MA-{len(CASES)+1:03d}"
    es = edmonds_model(g)
    if not is_matching(g, es):
        fail(cid, "Edmonds model invalid")
    chk = ["valid"]
    if small(g):
        card, _ = brute(g, lambda c, w: c)
        if card != len(es):
            fail(cid, f"Edmonds not maximum {len(es)} vs {card}")
        chk.append("size = brute force")
    H, _ = g.nx_simple(weighted=False)
    k = len(nx.max_weight_matching(H, maxcardinality=True))
    if k != len(es):
        fail(cid, f"Edmonds size {len(es)} vs NetworkX {k}")
    chk.append("size = NetworkX max_weight_matching(maxcardinality=True)")
    add("Edmonds", name, g.text(), "maximumMatching()", fmt_matching(g, es), "; ".join(chk), notes)


def case_mwm(name, g, maxcard=False, notes=""):
    cid = f"MA-{len(CASES)+1:03d}"
    es = mwm_model(g, maxcard)
    if not is_matching(g, es):
        fail(cid, "mwm invalid")
    wt = weight_of(g, es)
    chk = ["= NetworkX max_weight_matching"]
    if small(g):
        if maxcard:
            card, bw = brute(g, lambda c, w: (c, w))
            if card != len(es) or not close(bw, wt):
                fail(cid, f"mwm maxcard not optimal ({len(es)},{wt}) vs ({card},{bw})")
        else:
            _, bw = brute(g, lambda c, w: w)
            if not close(bw, wt):
                fail(cid, f"mwm not optimal {wt} vs {bw}")
        chk.append("weight = brute force")
    call = "maximumWeightMatching(weight:" + (", maximumCardinality: true)" if maxcard else ")")
    add("Maximum weight", name, g.text(), call, fmt_matching(g, es, wt, True), "; ".join(chk), notes)


def case_minwm(name, g, notes=""):
    cid = f"MA-{len(CASES)+1:03d}"
    es = minwm_model(g)
    wt = weight_of(g, es)
    chk = ["model: maximumWeightMatching on (1 + max) − w"]
    H, chosen = g.nx_simple()
    nm = nx.min_weight_matching(H)
    nes = sorted(chosen[frozenset(p)] for p in nm)
    if len(nes) != len(es) or not close(weight_of(g, nes), wt):
        fail(cid, f"min weight differs from NetworkX {nes} vs {es}")
    chk.append("= NetworkX min_weight_matching" if nes == es else "weight = NetworkX min_weight_matching")
    if small(g):
        card, bw = brute(g, lambda c, w: (c, -w))
        if card != len(es) or not close(bw, wt):
            fail(cid, f"min weight not optimal ({len(es)},{wt}) vs ({card},{bw})")
        chk.append("brute force")
    add("Minimum weight", name, g.text(), "minimumWeightMatching(weight:)", fmt_matching(g, es, wt, True),
        "; ".join(chk), notes)


def case_mwfm(name, g, left=None, right=None, notes="", via="bipartite"):
    cid = f"MA-{len(CASES)+1:03d}"
    left = left or g.left
    right = right or g.right
    res, port, pos = mwfm_model(g, left, right)
    if res != port:
        fail(cid, f"port differs from scipy {port} vs {res}")
    chk = ["= scipy linear_sum_assignment (biadjacency, +inf)", "port agrees"]
    H, chosen = g.nx_simple()
    nxerr = None
    try:
        nm = nx.bipartite.minimum_weight_full_matching(H, top_nodes=set(left))
    except ValueError:
        nm = None
    except nx.NetworkXError as e:
        nm, nxerr = None, str(e)
    if nxerr is not None:
        es = []
        exp = fmt_matching(g, es, 0, True)
        if res not in (None, ([], [])):
            fail(cid, "expected the empty matching")
        chk = [f"NetworkX raises NetworkXError ({nxerr}); scipy on a 0-row matrix gives the empty assignment"]
    elif res is None:
        exp = "nil (no full matching)"
        if nm is not None:
            fail(cid, "NetworkX found a full matching")
        chk.append("NetworkX raises ValueError")
    else:
        es = sorted(pos[a][b] for a, b in zip(*res))
        wt = weight_of(g, es)
        exp = fmt_matching(g, es, wt, True)
        npairs = {frozenset(p) for p in nm.items()}
        nes = sorted(chosen[p] for p in npairs)
        if not close(weight_of(g, nes), wt) or len(nes) != len(es):
            fail(cid, "weight differs from NetworkX")
        chk.append("= NetworkX minimum_weight_full_matching" if nes == es else "weight = NetworkX minimum_weight_full_matching")
        if small(g):
            k = min(len(left), len(right))
            card, bw = brute(g, lambda c, w: (c, -w))
            if card != k or not close(bw, wt):
                fail(cid, "full matching not optimal")
            chk.append("brute force")
    call = "minimumWeightFullMatching(weight:)" if via == "bipartite" else "minimumWeightFullMatching(bipartition: bipartition()!, weight:)"
    add("Full matching", name, g.text(), call, exp, "; ".join(chk), notes)


def fmt_matrix(M):
    return "[" + "; ".join(" ".join("∞" if x is None else fmtw(x) for x in row) for row in M) + "]" if M else "[] (0 rows)"


def case_lsa(name, M, maximize=False, cols=None, notes="", exact_int=False):
    cid = f"MA-{len(CASES)+1:03d}"
    nr = len(M)
    nc = cols if cols is not None else (len(M[0]) if nr else 0)
    port = lsap_port(M, maximize) if nr and nc else ([], [])
    chk = []
    if exact_int:
        sc = scipy_lsa(M, maximize)
        chk.append(f"scipy (float64) returns {sc}: rounded")
    else:
        sc = scipy_lsa(M, maximize) if nr and nc else ([], [])
        if sc != port:
            fail(cid, f"port {port} vs scipy {sc}")
        chk.append("= scipy linear_sum_assignment")
    if port is None:
        exp = "nil (infeasible)"
    else:
        r, c = port
        cost = 0
        for a, b in zip(r, c):
            cost = cost + M[a][b]
        exp = f"rows {fmtl(r)}; columns {fmtl(c)}; cost {fmtw(cost)}"
    # brute force
    if nr and nc and max(nr, nc) <= 7:
        best = None
        k = min(nr, nc)
        if nr <= nc:
            for perm in itertools.permutations(range(nc), nr):
                if all(M[i][perm[i]] is not None for i in range(nr)):
                    s = sum(M[i][perm[i]] for i in range(nr))
                    if best is None or (s > best if maximize else s < best):
                        best = s
        else:
            for perm in itertools.permutations(range(nr), nc):
                if all(M[perm[j]][j] is not None for j in range(nc)):
                    s = sum(M[perm[j]][j] for j in range(nc))
                    if best is None or (s > best if maximize else s < best):
                        best = s
        if (best is None) != (port is None):
            fail(cid, "feasibility differs from brute force")
        elif best is not None:
            r, c = port
            got = sum(M[a][b] for a, b in zip(r, c))
            if not close(got, best):
                fail(cid, f"lsa cost {got} vs brute {best}")
        chk.append("cost = brute force")
    call = f"linearSumAssignment(rowCount: {nr}, columnCount: {nc}" + (", maximize: true" if maximize else "") + ")"
    add("Assignment", name, fmt_matrix(M) if nr and nc else f"[] ({nr}×{nc})", call, exp, "; ".join(chk), notes)


def case_stable(name, pp, rp, notes=""):
    cid = f"MA-{len(CASES)+1:03d}"
    mate = stable_model(pp, rp)
    chk = stable_check(cid, pp, rp, mate)
    inp = "P " + fmtl(["".join(map(str, x)) if x else "·" for x in pp]) + "; R " + fmtl(["".join(map(str, x)) if x else "·" for x in rp])
    exp = "mates " + fmtl(["nil" if m is None else m for m in mate])
    add("Stable", name, inp, "stableMatching(proposerPreferences:reviewerPreferences:)", exp, chk, notes)


def case_trap(group, name, inp, call, why):
    add(group, name, inp, call, "trap", "precondition", why)


# --------------------------------------------------------------------------------------------
# The catalog
# --------------------------------------------------------------------------------------------

def build():
    E0 = G([], [])
    V1 = G([0], [])
    L1 = G([0], [(0, 0)])
    e1 = G([0, 1], [(0, 1)])
    par = G([0, 1], [(0, 1), (1, 0)], kind="multigraph")
    lp = G([0, 1], [(0, 0), (0, 1), (1, 1)])

    # --- Degenerate graphs, every graph entry point -------------------------------------
    for (nm, g) in [("empty graph", E0), ("one vertex", V1), ("one self-loop", L1),
                    ("one edge", e1), ("parallel pair", par), ("loops at both ends of an edge", lp),
                    ("two isolated vertices", G([0, 1], []))]:
        case_maximal(nm, g)
        case_edmonds(nm, g)
    case_mwm("empty graph", E0)
    case_mwm("one self-loop, weight 5 (never weighed)", G([0], [(0, 0, 5)]))
    case_mwm("one edge, negative weight", G([0, 1], [(0, 1, -3)]))
    case_mwm("one edge, negative weight, maximumCardinality", G([0, 1], [(0, 1, -3)]), maxcard=True)
    case_mwm("one edge, zero weight", G([0, 1], [(0, 1, 0)]),
             notes="a zero-weight edge is taken: its slack is 0 from the start (NetworkX agrees)")
    case_mwm("parallel pair, the later copy heavier", G([0, 1], [(0, 1, 2), (1, 0, 7)], kind="multigraph"))
    case_mwm("parallel pair, equal weights (earlier copy)", G([0, 1], [(0, 1, 4), (1, 0, 4)], kind="multigraph"))
    case_minwm("empty graph", E0)
    case_minwm("one edge", G([0, 1], [(0, 1, 9)]))

    # --- maximalMatching ----------------------------------------------------------------
    case_maximal("NetworkX docstring graph", G([1, 2, 3, 4, 5], [(1, 2), (1, 3), (2, 3), (2, 4), (3, 5), (4, 5)]))
    case_maximal("path P4: greedy takes the middle edge first", G([0, 1, 2, 3], [(1, 2), (0, 1), (2, 3)]),
                 notes="maximal, not maximum: size 1 where 2 exists")
    case_maximal("path P4 in path order", P(4))
    case_maximal("star S4", G(range(5), [(0, i) for i in range(1, 5)]))
    case_maximal("triangle", K(3))
    case_maximal("K5", K(5))
    case_maximal("loop first, then edges", G([0, 1, 2], [(0, 0), (0, 1), (1, 2)]))
    case_maximal("multigraph: parallel copies after a taken edge skipped",
                 G([0, 1, 2], [(0, 1), (0, 1), (1, 2), (2, 0)], kind="multigraph"))
    case_maximal("string vertices, edge stored v–u", G(["b", "a", "c"], [("a", "b"), ("c", "b")]))
    case_maximal("grid 3×3", grid(3, 3))
    case_maximal("random lcg(12,20,1)", lcg_graph(12, 20, 1))

    # --- Checks -------------------------------------------------------------------------
    p4 = P(4)
    case_check("empty set on the empty graph", E0, [])
    case_check("empty set on one edge", e1, [], notes="a matching, not maximal")
    case_check("one edge", e1, [0])
    case_check("P4 middle edge", p4, [1])
    case_check("P4 outer edges", p4, [0, 2])
    case_check("P4 adjacent edges", p4, [0, 1])
    case_check("P4 all edges", p4, [0, 1, 2])
    case_check("self-loop alone", L1, [0], notes="a self-loop is never in a matching (NetworkX agrees)")
    case_check("self-loop with an edge", G([0, 1, 2], [(0, 0), (1, 2)]), [0, 1])
    case_check("loop graph, loops ignored for maximality", G([0, 1, 2], [(0, 0), (1, 2)]), [1],
               notes="vertex 0 has only a loop; the matching is still maximal")
    case_check("repeated position", e1, [0, 0], notes="the same edge twice shares its endpoints")
    case_check("parallel copies both listed", par, [0, 1])
    case_check("one parallel copy", par, [1])
    case_check("K4 perfect", K(4), [0, 5])
    case_check("NetworkX valid_not_path", G(range(6), [(0, 1), (0, 3), (0, 4), (1, 2), (1, 4), (2, 5), (3, 4), (4, 5)]), [1, 4, 5],
               notes="positions of 0–3, 2–5, 1–4")
    case_check("isolated vertex blocks perfection", G([0, 1, 2], [(0, 1)]), [0])
    case_check("unordered position list", K(4), [5, 0])

    # --- Hopcroft–Karp ------------------------------------------------------------------
    case_hk("empty bipartite graph", bip([], [], []))
    case_hk("left only", bip([0, 1], [], []))
    case_hk("one edge", bip([0], [1], [(0, 1)]))
    case_hk("edge given right endpoint first (stored left first)", bip(["a"], ["x"], [("x", "a")]))
    case_hk("K2,2", Kb(2, 2))
    case_hk("K3,3", Kb(3, 3))
    case_hk("K2,4 (left smaller)", Kb(2, 4))
    case_hk("K4,2 (right smaller)", Kb(4, 2))
    case_hk("star, one left centre", bip([0], [1, 2, 3], [(0, 1), (0, 2), (0, 3)]))
    case_hk("star, one right centre", bip([0, 1, 2], [3], [(0, 3), (1, 3), (2, 3)]))
    case_hk("path a–x–b–y needs an augmenting path", bip(["a", "b"], ["x", "y"], [("a", "x"), ("b", "x"), ("a", "y")]),
            notes="greedy phase 1 takes a–x; phase 2 augments b–x–a–y")
    case_hk("ladder listed in reverse: the greedy first phase suffices",
            bip(list(range(5)), list(range(5, 10)),
                [(0, 5), (0, 6), (1, 6), (1, 7), (2, 7), (2, 8), (3, 8), (3, 9), (4, 5)][::-1]),
            notes="")
    case_hk("NetworkX test graph (12 vertices, top 0..5)",
            G(range(12), [(0, 7), (0, 8), (2, 6), (2, 9), (3, 8), (4, 8), (4, 9), (5, 11)], kind="bipartite",
              left=[0, 1, 2, 3, 4, 5], right=[6, 7, 8, 9, 10, 11]))
    case_hk("NetworkX disconnected graph", bip([0, 1, 2], [3, 4, 5], [(0, 3), (1, 3), (1, 4)]))
    case_hk("isolated vertices on both sides", bip([0, 1, 2], [3, 4, 5], [(1, 4)]))
    case_hk("lcgb(6,6,14,3)", lcg_bipartite(6, 6, 14, 3))
    case_hk("lcgb(8,5,20,11)", lcg_bipartite(8, 5, 20, 11))
    case_hk("lcgb(10,10,25,5)", lcg_bipartite(10, 10, 25, 5))
    case_hk("lcgb(30,30,90,2)", lcg_bipartite(30, 30, 90, 2), notes="several phases")
    case_hk("Graph: path P6 via canonical bipartition", P(6), via="graph")
    case_hk("Graph: C6", C(6), via="graph")
    case_hk("Graph: grid 3×4", grid(3, 4), via="graph")
    case_hk("Graph: two components, left = least vertex", G([5, 0, 1, 2, 3], [(0, 1), (2, 3), (5, 3)]), via="graph",
            notes="vertices out of numeric order: left is [5, 0, 2]")
    case_hk("Graph: multigraph, parallel copies", G([0, 1, 2], [(0, 1), (0, 1), (0, 2)], kind="multigraph"), via="graph",
            notes="the first copy in 0's row is matched")
    case_hk("Graph: even cycle with chords (K3,3 as a plain graph)",
            G(range(6), [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]), via="graph")
    case_hk("Hypercube Q3", G(range(8),
                               [(a, b) for a in range(8) for b in range(a + 1, 8) if bin(a ^ b).count("1") == 1]),
            via="graph")
    case_hk("C6 as a bipartite graph, edges listed in reverse", bip([0, 1, 2], [3, 4, 5], [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5), (0, 5)][::-1]))

    # --- Edmonds (general maximum cardinality) ------------------------------------------
    case_edmonds("triangle", K(3))
    case_edmonds("C5", C(5))
    case_edmonds("C7", C(7))
    case_edmonds("K4", K(4))
    case_edmonds("K5", K(5))
    case_edmonds("K6", K(6))
    case_edmonds("P5", P(5))
    case_edmonds("star S5", G(range(6), [(0, i) for i in range(1, 6)]))
    case_edmonds("Petersen", petersen())
    case_edmonds("triangle with a pendant: augmenting path through a blossom",
                 G(range(4), [(0, 1), (1, 2), (2, 0), (2, 3)]))
    case_edmonds("blossom then stem: 0 free root, path enters C5 at its base",
                 G(range(7), [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1), (4, 6)]))
    case_edmonds("flower: C5 with stem and an exit at the far side",
                 G(range(8), [(6, 0), (0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 7), (5, 6)]))
    case_edmonds("nested blossoms (triangle inside C5)",
                 G(range(9), [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5), (5, 0), (5, 6), (6, 7), (7, 8), (4, 8)]))
    case_edmonds("two triangles joined by an edge", G(range(6), [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]))
    case_edmonds("barbell K4–K4", G(range(8), [(a, b) for a in range(4) for b in range(a + 1, 4)] +
                                     [(a, b) for a in range(4, 8) for b in range(a + 1, 8)] + [(3, 4)]))
    case_edmonds("odd wheel W5", G(range(6), [(0, i) for i in range(1, 6)] + [(i, i % 5 + 1) for i in range(1, 6)]))
    case_edmonds("vertex order matters: P3 numbered from the middle", G([1, 0, 2], [(0, 1), (1, 2)]))
    case_edmonds("multigraph: triangle with a doubled edge", G(range(3), [(0, 1), (1, 0), (1, 2), (2, 0)], kind="multigraph"))
    case_edmonds("loops everywhere on a P4", G(range(4), [(0, 0), (0, 1), (1, 1), (1, 2), (2, 3), (3, 3)]))
    case_edmonds("grid 3×3 (odd: one vertex free)", grid(3, 3))
    case_edmonds("grid 4×4", grid(4, 4))
    case_edmonds("bipartite input K3,3", Kb(3, 3))
    case_edmonds("Tutte's example: no perfect matching (K1,3 of triangles)",
                 G(range(10), [(0, 1), (0, 4), (0, 7), (1, 2), (2, 3), (3, 1), (4, 5), (5, 6), (6, 4), (7, 8), (8, 9), (9, 7)]))
    case_edmonds("lcg(10,15,1)", lcg_graph(10, 15, 1))
    case_edmonds("lcg(12,18,7)", lcg_graph(12, 18, 7))
    case_edmonds("lcg(14,21,3)", lcg_graph(14, 21, 3))
    case_edmonds("lcg(15,30,9)", lcg_graph(15, 30, 9))
    case_edmonds("lcg(40,80,4)", lcg_graph(40, 80, 4), notes="size against NetworkX only")
    case_edmonds("lcg(60,90,8)", lcg_graph(60, 90, 8), notes="size against NetworkX only")
    case_edmonds("stem into a blossom: the first free root augments only through the blossom",
                 G(["s", "t", "a", "b", "c", "d", "r", "f"], [("s", "t"), ("a", "b"), ("c", "d"), ("t", "a"), ("b", "c"), ("d", "t"), ("r", "s"), ("a", "f")]),
                 notes="without contraction the search from r fails and f's search finds the other path: different edges, same size")
    for (n_, m_, s_) in [(10, 13, 6), (10, 14, 0), (13, 20, 1), (14, 18, 6), (14, 23, 2)]:
        case_edmonds(f"lcg({n_},{m_},{s_}): needs a blossom", lcg_graph(n_, m_, s_),
                     notes="a search without blossom contraction returns a smaller matching")
    case_edmonds("blossom expansion on augmentation (C5 + two pendants)",
                 G(range(7), [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 5), (3, 6)]))

    # --- Maximum weight (general) -------------------------------------------------------
    case_mwm("NetworkX two_path", G(["one", "two", "three"], [("one", "two", 10), ("two", "three", 11)]))
    case_mwm("NetworkX path", G([1, 2, 3, 4], [(1, 2, 5), (2, 3, 11), (3, 4, 5)]))
    case_mwm("NetworkX path, maximumCardinality", G([1, 2, 3, 4], [(1, 2, 5), (2, 3, 11), (3, 4, 5)]), maxcard=True)
    case_mwm("NetworkX square", G([1, 4, 2, 3], [(1, 4, 2), (2, 3, 2), (1, 2, 1), (3, 4, 4)]))
    case_mwm("NetworkX floating-point weights", G([1, 2, 3, 4], [(1, 2, math.pi), (2, 3, math.exp(1)), (1, 3, 3.0), (1, 4, math.sqrt(2.0))]))
    neg = G([1, 2, 3, 4], [(1, 2, 2), (1, 3, -2), (2, 3, 1), (2, 4, -1), (3, 4, -6)])
    case_mwm("NetworkX negative weights", neg)
    case_mwm("NetworkX negative weights, maximumCardinality", neg, maxcard=True)
    sb = G([1, 2, 3, 4], [(1, 2, 8), (1, 3, 9), (2, 3, 10), (3, 4, 7)])
    case_mwm("NetworkX s_blossom", sb)
    case_mwm("NetworkX s_blossom extended", G([1, 2, 3, 4, 6, 5], [(1, 2, 8), (1, 3, 9), (2, 3, 10), (3, 4, 7), (1, 6, 5), (4, 5, 6)]))
    case_mwm("NetworkX s_t_blossom", G([1, 2, 3, 4, 5, 6], [(1, 2, 9), (1, 3, 8), (2, 3, 10), (1, 4, 5), (4, 5, 4), (1, 6, 3)]))
    case_mwm("NetworkX s_t_blossom reweighted", G([1, 2, 3, 4, 5, 6], [(1, 2, 9), (1, 3, 8), (2, 3, 10), (1, 4, 5), (4, 5, 3), (1, 6, 4)]))
    case_mwm("NetworkX s_t_blossom, 1–6 replaced by 3–6", G([1, 2, 3, 4, 5, 6], [(1, 2, 9), (1, 3, 8), (2, 3, 10), (1, 4, 5), (4, 5, 3), (3, 6, 4)]))
    case_mwm("NetworkX nested_s_blossom", G([1, 2, 3, 4, 5, 6], [(1, 2, 9), (1, 3, 9), (2, 3, 10), (2, 4, 8), (3, 5, 8), (4, 5, 10), (5, 6, 6)]))
    case_mwm("NetworkX nested_s_blossom_relabel", G([1, 2, 7, 3, 4, 5, 6, 8], [(1, 2, 10), (1, 7, 10), (2, 3, 12), (3, 4, 20), (3, 5, 20), (4, 5, 25), (5, 6, 10), (6, 7, 10), (7, 8, 8)]))
    case_mwm("NetworkX nested_s_blossom_expand", G([1, 2, 3, 4, 5, 6, 7, 8], [(1, 2, 8), (1, 3, 8), (2, 3, 10), (2, 4, 12), (3, 5, 12), (4, 5, 14), (4, 6, 12), (5, 7, 12), (6, 7, 14), (7, 8, 12)]))
    case_mwm("NetworkX s_blossom_relabel_expand", G([1, 2, 5, 6, 3, 4, 8, 7], [(1, 2, 23), (1, 5, 22), (1, 6, 15), (2, 3, 25), (3, 4, 22), (4, 5, 25), (4, 8, 14), (5, 7, 13)]))
    case_mwm("NetworkX nested_s_blossom_relabel_expand", G([1, 2, 3, 8, 4, 5, 7, 6], [(1, 2, 19), (1, 3, 20), (1, 8, 8), (2, 3, 25), (2, 4, 18), (3, 5, 18), (4, 5, 13), (4, 7, 7), (5, 6, 7)]))
    nasty = [(1, 2, 45), (1, 5, 45), (2, 3, 50), (3, 4, 45), (4, 5, 50), (1, 6, 30), (3, 9, 35), (4, 8, 35), (5, 7, 26), (9, 10, 5)]
    order = [1, 2, 5, 3, 4, 6, 9, 8, 7, 10]
    case_mwm("NetworkX nasty_blossom1", G(order, nasty))
    case_mwm("NetworkX nasty_blossom2", G(order, nasty[:7] + [(4, 8, 26), (5, 7, 40), (9, 10, 5)]))
    case_mwm("NetworkX nasty_blossom_least_slack", G(order, nasty[:7] + [(4, 8, 28), (5, 7, 26), (9, 10, 5)]))
    case_mwm("NetworkX nasty_blossom_augmenting", G([1, 2, 7, 3, 4, 5, 6, 8, 11, 9, 10, 12],
             [(1, 2, 45), (1, 7, 45), (2, 3, 50), (3, 4, 45), (4, 5, 95), (4, 6, 94), (5, 6, 94), (6, 7, 50), (1, 8, 30), (3, 11, 35), (5, 9, 36), (7, 10, 26), (11, 12, 5)]))
    case_mwm("NetworkX nasty_blossom_expand_recursively", G([1, 2, 3, 4, 5, 8, 7, 6, 10, 9],
             [(1, 2, 40), (1, 3, 40), (2, 3, 60), (2, 4, 55), (3, 5, 55), (4, 5, 50), (1, 8, 15), (5, 7, 30), (7, 6, 10), (8, 10, 10), (4, 9, 30)]))
    case_mwm("ties: unit-weight triangle", G(range(3), [(0, 1, 1), (1, 2, 1), (2, 0, 1)]))
    case_mwm("ties: unit-weight C4 (two optimal matchings)", G(range(4), [(0, 1, 1), (1, 2, 1), (2, 3, 1), (3, 0, 1)]))
    case_mwm("ties: C4 listed from a different start", G(range(4), [(1, 2, 1), (2, 3, 1), (3, 0, 1), (0, 1, 1)]))
    case_mwm("ties: K4 all weights 2", G(range(4), [(a, b, 2) for a in range(4) for b in range(a + 1, 4)]))
    case_mwm("one heavy edge beats two light", G(range(4), [(0, 1, 1), (1, 2, 3), (2, 3, 1)]))
    case_mwm("one heavy edge vs two light, maximumCardinality", G(range(4), [(0, 1, 1), (1, 2, 3), (2, 3, 1)]), maxcard=True)
    case_mwm("all weights negative", G(range(4), [(0, 1, -1), (1, 2, -2), (2, 3, -1)]))
    case_mwm("all weights negative, maximumCardinality", G(range(4), [(0, 1, -1), (1, 2, -2), (2, 3, -1)]), maxcard=True)
    case_mwm("zero weights, maximumCardinality", G(range(4), [(0, 1, 0), (1, 2, 0), (2, 3, 0)]), maxcard=True)
    case_mwm("float halves (Double path, delta3 = slack/2)", G(range(4), [(0, 1, 0.5), (1, 2, 1.5), (2, 3, 0.5), (3, 0, 1.25)]))
    case_mwm("odd integer weights on a triangle plus pendant", G(range(4), [(0, 1, 3), (1, 2, 5), (2, 0, 7), (2, 3, 1)]))
    case_mwm("loop heavier than every edge (never weighed)", G(range(3), [(0, 0, 100), (0, 1, 2), (1, 2, 3)]))
    case_mwm("multigraph: heaviest parallel copy chosen", G(range(3), [(0, 1, 1), (1, 2, 2), (0, 1, 5), (1, 2, 5)], kind="multigraph"))
    case_mwm("lcgw(10,20,1,9)", lcg_graph(10, 20, 1, 9))
    case_mwm("lcgw(12,25,2,5)", lcg_graph(12, 25, 2, 5))
    case_mwm("lcgw(12,25,2,5), maximumCardinality", lcg_graph(12, 25, 2, 5), maxcard=True)
    case_mwm("lcgw(14,30,6,3) many ties", lcg_graph(14, 30, 6, 3))
    case_mwm("lcgw(40,100,3,50)", lcg_graph(40, 100, 3, 50), notes="against NetworkX only")
    case_mwm("bipartite K3,3 weights i·j", G(range(6), [(i, 3 + j, (i + 1) * (j + 1)) for i in range(3) for j in range(3)]))
    case_mwm("Petersen unit weights, maximumCardinality", G(petersen().V, [(u, v, 1) for (u, v, _) in petersen().E]), maxcard=True)

    # --- Minimum weight (maximum cardinality) -------------------------------------------
    case_minwm("NetworkX two_path", G(["one", "two", "three"], [("one", "two", 10), ("two", "three", 11)]))
    case_minwm("NetworkX path", G([1, 2, 3, 4], [(1, 2, 5), (2, 3, 11), (3, 4, 5)]))
    case_minwm("NetworkX square", G([1, 4, 2, 3], [(1, 4, 2), (2, 3, 2), (1, 2, 1), (3, 4, 4)]))
    case_minwm("NetworkX negative weights", neg)
    case_minwm("NetworkX s_blossom", sb)
    case_minwm("NetworkX min_weight_matching_max_cardinality", G([1, 2, 3, 4], [(1, 2, 1000), (2, 3, 2), (3, 4, 3000)]))
    case_minwm("NetworkX floating-point weights", G([1, 2, 3, 4], [(1, 2, math.pi), (2, 3, math.exp(1)), (1, 3, 3.0), (1, 4, math.sqrt(2.0))]))
    case_minwm("isolated vertex first (NetworkX reorders vertices)", G([9, 1, 2, 3, 4], [(1, 2, 1), (2, 3, 1), (3, 4, 1), (4, 1, 1)]),
               notes="NetworkX builds a new graph from the edges, dropping isolated vertices and reordering")
    case_minwm("lcgw(10,20,4,7)", lcg_graph(10, 20, 4, 7))

    # --- Minimum weight full matching (bipartite) ---------------------------------------
    case_mwfm("NetworkX incomplete graph", bip([1, 2], [3, 4], [(1, 4, 100), (2, 3, 100), (2, 4, 50)]))
    case_mwfm("NetworkX no full matching", bip([1, 2, 3], [4, 5, 6], [(1, 4, 100), (2, 4, 100), (3, 4, 50), (3, 5, 50), (3, 6, 50)]))
    sq = [(0, 3, 400), (0, 4, 150), (0, 5, 400), (1, 3, 400), (1, 4, 450), (1, 5, 600), (2, 3, 300), (2, 4, 225), (2, 5, 300)]
    case_mwfm("NetworkX square", bip([0, 1, 2], [3, 4, 5], sq))
    sl = [(0, 3, 400), (0, 4, 150), (0, 5, 400), (0, 6, 1), (1, 3, 400), (1, 4, 450), (1, 5, 600), (1, 6, 2), (2, 3, 300), (2, 4, 225), (2, 5, 290), (2, 6, 3)]
    case_mwfm("NetworkX smaller left", bip([0, 1, 2], [3, 4, 5, 6], sl))
    case_mwfm("NetworkX smaller left, sides swapped (top = right)", bip([3, 4, 5, 6], [0, 1, 2], sl),
              notes="the larger side as left: scipy transposes")
    sr = [(0, 4, 400), (0, 5, 400), (0, 6, 300), (1, 4, 150), (1, 5, 450), (1, 6, 225), (2, 4, 400), (2, 5, 600), (2, 6, 290), (3, 4, 1), (3, 5, 2), (3, 6, 3)]
    case_mwfm("NetworkX smaller right", bip([0, 1, 2, 3], [4, 5, 6], sr))
    case_mwfm("NetworkX negative weights", bip([0, 1], [2, 3], [(0, 2, -2), (0, 3, 0.2), (1, 2, -2), (1, 3, 0.3)]))
    case_mwfm("empty bipartite graph", bip([], [], []))
    case_mwfm("left only, no right vertices", bip([0, 1], [], []), notes="min(|L|, |R|) = 0: the empty matching is full")
    case_mwfm("ties: K2,2 all zero", bip([0, 1], [2, 3], [(0, 2, 0), (0, 3, 0), (1, 2, 0), (1, 3, 0)]),
              notes="scipy's reversed column order gives the identity")
    case_mwfm("ties: K3,3 all ones", bip([0, 1, 2], [3, 4, 5], [(i, 3 + j, 1) for i in range(3) for j in range(3)]))
    case_mwfm("Graph: path P4 via bipartition", G(range(4), [(0, 1, 5), (1, 2, 1), (2, 3, 5)]), left=[0, 2], right=[1, 3], via="graph")
    case_mwfm("Graph: C6 weights by position", G(range(6), [(i, (i + 1) % 6, i + 1) for i in range(6)]), left=[0, 2, 4], right=[1, 3, 5], via="graph")
    case_mwfm("lcgbw(5,5,15,1,9)", lcg_bipartite(5, 5, 15, 1, 9))
    case_mwfm("lcgbw(4,7,20,2,20)", lcg_bipartite(4, 7, 20, 2, 20))
    case_mwfm("lcgbw(6,6,12,9,4) sparse, maybe infeasible", lcg_bipartite(6, 6, 12, 9, 4))

    # --- linearSumAssignment ------------------------------------------------------------
    N = None
    case_lsa("scipy square", [[400, 150, 400], [400, 450, 600], [300, 225, 300]])
    case_lsa("scipy rectangular", [[400, 150, 400, 1], [400, 450, 600, 2], [300, 225, 300, 3]])
    case_lsa("scipy square 2", [[10, 10, 8], [9, 8, 1], [9, 7, 4]])
    case_lsa("scipy rectangular 2", [[10, 10, 8, 11], [9, 8, 1, 1], [9, 7, 4, 10]])
    case_lsa("scipy with forbidden entries", [[10, N, N], [N, N, 1], [N, 7, N]])
    case_lsa("scipy square, maximize", [[400, 150, 400], [400, 450, 600], [300, 225, 300]], maximize=True)
    case_lsa("scipy rectangular, maximize", [[400, 150, 400, 1], [400, 450, 600, 2], [300, 225, 300, 3]], maximize=True)
    case_lsa("tall matrix (transposed internally)", [[1, 2], [3, 4], [0, 9], [5, 1]])
    case_lsa("tall matrix, maximize", [[1, 2], [3, 4], [0, 9], [5, 1]], maximize=True)
    case_lsa("0×0", [], cols=0)
    case_lsa("2×0", [[], []], cols=0)
    case_lsa("1×1", [[7]])
    case_lsa("1×3 picks the least", [[3, 1, 2]])
    case_lsa("3×1 picks the least", [[3], [1], [2]])
    case_lsa("constant 3×3: identity (reversed column scan)", [[5] * 3 for _ in range(3)])
    case_lsa("zeros 3×4", [[0] * 4 for _ in range(3)])
    case_lsa("zeros 4×3", [[0] * 3 for _ in range(4)])
    case_lsa("negative costs", [[-1, -5], [-3, -2]])
    case_lsa("mixed signs, maximize", [[-1, 4, 0], [2, -3, 1], [0, 0, 5]], maximize=True)
    case_lsa("floats", [[0.5, 1.25], [1.0, 0.75]])
    case_lsa("infeasible: a row all forbidden", [[1, 2, N], [N, N, N]])
    case_lsa("infeasible: two rows need one column", [[1, N], [2, N]])
    case_lsa("feasible only one way", [[1, N, N], [N, N, 2], [3, 4, N]])
    case_lsa("rectangular with a forbidden column", [[1, N, 3], [2, N, 1]])
    case_lsa("ties: anti-diagonal equal", [[1, 0], [0, 1]])
    case_lsa("ties: two optima", [[1, 2], [2, 3]])
    case_lsa("ties: Latin square 3×3", [[0, 1, 2], [1, 2, 0], [2, 0, 1]])
    case_lsa("permutation matrix costs", [[0, 0, 1, 0], [1, 0, 0, 0], [0, 0, 0, 1], [0, 1, 0, 0]], maximize=True)
    r = LCG(42)
    M6 = [[r.next() % 10 for _ in range(6)] for _ in range(6)]
    case_lsa("lcg 6×6 digits", M6, notes="row-major draws % 10 from LCG(42)")
    M57 = [[r.next() % 4 for _ in range(7)] for _ in range(5)]
    case_lsa("lcg 5×7 small range (many ties)", M57, notes="continuing the same LCG(42) stream")
    big = 2 ** 53
    case_lsa("integers beyond 2^53: exact", [[big + 1, big], [big, big]], exact_int=True,
             notes="Int arithmetic is exact; scipy rounds to float64 and returns the worse [0, 1]")

    # --- Stable matching ----------------------------------------------------------------
    case_stable("Gale–Shapley 1962 example 1 (3×3)", [[0, 1, 2], [1, 2, 0], [2, 0, 1]], [[1, 2, 0], [2, 0, 1], [0, 1, 2]],
                notes="each proposer gets a first choice")
    case_stable("same instance, roles swapped", [[1, 2, 0], [2, 0, 1], [0, 1, 2]], [[0, 1, 2], [1, 2, 0], [2, 0, 1]],
                notes="the reviewer-optimal matching of the original, read from the other side")
    case_stable("everyone agrees (serial dictatorship)", [[0, 1, 2]] * 3, [[0, 1, 2]] * 3)
    case_stable("one each", [[0]], [[0]])
    case_stable("no proposers", [], [[], []])
    case_stable("no reviewers", [[], []], [])
    case_stable("empty lists", [[], []], [[], []])
    case_stable("one-sided acceptability is unacceptable", [[0]], [[]])
    case_stable("more proposers than reviewers", [[0, 1], [0, 1], [1, 0]], [[2, 0, 1], [1, 2, 0]])
    case_stable("more reviewers than proposers", [[2, 0], [2, 1]], [[0, 1], [1, 0], [1, 0]])
    case_stable("incomplete lists, a proposer left single", [[0], [0, 1], [1]], [[1, 0], [2, 1]])
    case_stable("cyclic 3×3, reviewers reversed: two stable matchings", [[0, 1, 2], [1, 2, 0], [2, 0, 1]], [[1, 2, 0], [2, 0, 1], [0, 1, 2]][::-1])
    case_stable("4×4 Gusfield–Irving style", [[3, 1, 2, 0], [1, 0, 2, 3], [0, 1, 2, 3], [0, 3, 1, 2]], [[0, 1, 2, 3], [0, 3, 2, 1], [1, 0, 2, 3], [3, 1, 0, 2]])
    rr = LCG(7)

    def perm(k):
        xs = list(range(k))
        for i in range(k - 1, 0, -1):
            j = rr.next() % (i + 1)
            xs[i], xs[j] = xs[j], xs[i]
        return xs
    case_stable("random 5×5 complete (LCG(7) Fisher–Yates)", [perm(5) for _ in range(5)], [perm(5) for _ in range(5)])
    case_stable("random 6×6 complete (continuing LCG(7))", [perm(6) for _ in range(6)], [perm(6) for _ in range(6)])
    case_stable("random 5×4 truncated lists", [perm(4)[:2] for _ in range(5)], [perm(5)[:3] for _ in range(4)])

    # --- Traps --------------------------------------------------------------------------
    case_trap("Checks", "position out of range", "V [0, 1]; E [0-1]", "isMatching([1])", "positions must be positions of `edges`")
    case_trap("Hopcroft–Karp", "bipartition of another graph", "V [0, 1, 2]; E [0-1]; bipartition of P3", "maximumBipartiteMatching(bipartition:)", "vertex count differs")
    case_trap("Hopcroft–Karp", "bipartition with an edge inside a side", "V [0, 1, 2, 3]; E [0-1]; bipartition from a graph with edges 0-2, 1-3", "maximumBipartiteMatching(bipartition:)", "an edge does not cross; checked in the row scan")
    case_trap("Maximum weight", "NaN weight", "V [0, 1]; E [0-1:nan]", "maximumWeightMatching(weight:)", "weights must not be NaN")
    case_trap("Maximum weight", "infinite weight", "V [0, 1]; E [0-1:inf]", "maximumWeightMatching(weight:)", "Double weights must be finite (dual arithmetic)")
    case_trap("Assignment", "negative row count", "", "linearSumAssignment(rowCount: -1, columnCount: 2)", "counts ≥ 0")
    case_trap("Assignment", "NaN cost", "[nan]", "linearSumAssignment(rowCount: 1, columnCount: 1)", "costs must not be NaN (scipy: invalid numeric entries)")
    case_trap("Full matching", "NaN weight", "L [0]; R [1]; E [0-1:nan]", "minimumWeightFullMatching(weight:)", "weights must not be NaN")
    case_trap("Stable", "reviewer index out of range", "P [[1]]; R [[0]]", "stableMatching", "every listed index in range")
    case_trap("Stable", "repeated entry in a list", "P [[0, 0]]; R [[0]]", "stableMatching", "strict preferences: no repeats")


HEADER = """# MatchingModule: case catalog (MA-001 – MA-{last}, {count} cases)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
scipy==1.18.1 python3 ref.py`; `--write` regenerates this file). Expected is the API's documented
output (api.md, Determinism); the last column says what each row was checked against. ref.py's
docstring lists the reference for each entry point.

## Notation

* **Graphs.** `V [..]; E [..]`: vertices in order (their vertex indices), then edges at positions
  0, 1, …, each `u-v` or `u-v:w` (weight w; unweighted rows use no weight). Rows list edge ends in
  position order (an `UndirectedAdjacencyList` built by inserting `E` in order; a self-loop twice).
  `multigraph` rows have parallel edges, so tests need an in-file `Graph` conformer whose rows are
  in position order. `L [..]; R [..]; E [..]` is a `BipartiteGraph(left:right:edges:)`, so
  `vertices` is L then R.
* **Generators.** `K(n)` every pair i < j lexicographic; `C(n)` edges i–(i+1) mod n; `P(n)` the
  path; `Kb(a,b)` the `BipartiteGraph` with left 0..<a, right a..<a+b, edges row-major;
  `grid(r,c)` vertex i·c+j, edges right then down, row-major; `nx(petersen)` NetworkX's
  `petersen_graph()` nodes and `edges()`. `lcg(n,m,seed)`: a 64-bit LCG, x ← x·6364136223846793005
  + 1442695040888963407 (mod 2⁶⁴), each draw x >> 33; an edge is two draws (u = d % n, v = d % n),
  skipped when u = v or the pair is already an edge, until m edges. `lcgw(n,m,seed,k)` adds a third
  draw per accepted edge, weight 1 + d % k. `lcgb(l,r,m,seed)` / `lcgbw(…,k)`: a `BipartiteGraph`,
  left 0..<l, right l..<l+r, an edge u = d % l, v = l + d % r, repeats skipped.
* **Matchings.** `edges [..] {..}`: `Matching.edges` (positions, ascending) and the pairs they
  join; `weight` is `Matching.weight` (the sum in `edges` order; unweighted entry points have
  `weight == edges.count`); `perfect` when `isPerfect`. Hopcroft–Karp rows add the König cover
  (the vertices of a minimum vertex cover built from the matching by an alternating search from
  the free left vertices, in `vertices` order: the test-side certificate of maximality, and
  Covering's future `minimumVertexCover()`) and the number of phases (a benchmark-only property;
  tests do not assert it).
* **Assignment.** A row-major matrix, rows separated by `;`, `∞` a forbidden entry (the closure
  returns nil). Expected: scipy's `(row_ind, col_ind)` as `rows`, `columns`, and the total cost.
* **Stable matching.** `P` lists each proposer's preference list (reviewer indices, best first,
  written as digits; `·` an empty list), `R` each reviewer's. Expected: `mate(ofProposer:)` for
  each proposer.
* **trap** rows are preconditions: tests run them as exit tests (`#expect(processExitsWith:)`).

| ID | Group | Case | Input | Call | Expected | Checked |
|---|---|---|---|---|---|---|
"""


def stress():
    """Random cross-checks beyond the catalog: the scipy port on tie-heavy matrices with forbidden
    entries, Hopcroft-Karp against NetworkX, Edmonds against NetworkX, stable matching by brute force."""
    import random
    rnd = random.Random(1)
    for t in range(3000):
        nr, nc = rnd.randint(1, 7), rnd.randint(1, 7)
        M = [[(None if rnd.random() < 0.2 else rnd.randint(-3, 3)) for _ in range(nc)] for _ in range(nr)]
        mx = rnd.random() < 0.3
        a, b = lsap_port(M, mx), scipy_lsa(M, mx)
        assert a == b, (M, mx, a, b)
    for t in range(400):
        l, r = rnd.randint(1, 9), rnd.randint(1, 9)
        m = rnd.randint(0, l * r)
        g = lcg_bipartite(l, r, m, t)
        es, _ = hk_model(g, g.left)
        H, chosen = g.nx_simple(weighted=False)
        nxm = nx.bipartite.hopcroft_karp_matching(H, top_nodes=set(g.left))
        got = sorted(chosen[frozenset(p)] for p in nxm.items() if p[0] in set(g.left))
        assert got == es, (g.E, got, es)
        cov = konig_cover(g, g.left, es)
        assert set(cov) == set(nx.bipartite.to_vertex_cover(H, nxm, top_nodes=set(g.left)))
    for t in range(600):
        n = rnd.randint(1, 22)
        m = rnd.randint(0, min(50, n * (n - 1) // 2))
        g = lcg_graph(n, m, t) if n > 1 else G([0], [])
        es = edmonds_model(g)
        assert is_matching(g, es)
        H, _ = g.nx_simple(weighted=False)
        assert len(es) == len(nx.max_weight_matching(H, maxcardinality=True)), (g.E, es)
    for t in range(300):
        P, R = rnd.randint(0, 5), rnd.randint(0, 5)
        pp = [rnd.sample(range(R), rnd.randint(0, R)) for _ in range(P)]
        rp = [rnd.sample(range(P), rnd.randint(0, P)) for _ in range(R)]
        stable_check(f"stress-{t}", pp, rp, stable_model(pp, rp))
    print("stress: all agree")


def main():
    if "--stress" in sys.argv:
        stress()
    build()
    if FAILS:
        print("\n".join(FAILS))
        sys.exit(1)
    if "--write" in sys.argv:
        out = HEADER.replace("{last}", f"{len(CASES):03d}").replace("{count}", str(len(CASES)))
        for i, (grp, name, inp, call, exp, chk, notes) in enumerate(CASES):
            nm = name + (f" ({notes})" if notes else "")
            out += f"| MA-{i+1:03d} | {grp} | {nm} | {inp} | {call} | {exp} | {chk} |\n".replace("\n|", " |", 0)
        open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cases.md"), "w").write(out)
    print(f"{len(CASES)} cases; all values agree")


if __name__ == "__main__":
    main()
