"""Independent reference for the Centrality module (catalog cases.md, CE-...).

Run:  uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3 ref.py
      ... python3 ref.py --fill    rewrite '?' Expected cells of cases.md with computed values

Every Expected cell is recomputed by the model of api.md written here in index space (rows in
`outEdges` / `incidentEdges` order, an undirected self-loop twice in its row; Brandes with
successor-side accumulation; the shifted power iteration, Katz, PageRank and HITS iterations
exactly as api.md specifies them, unified stop rule ||x_k - x_(k-1)||_1 < n * tolerance), and
checked independently:

* betweenness against the definition: all-pairs distances by Floyd-Warshall over the edge list,
  shortest-path counts sigma_st over edge sequences, BC(v) = sum sigma_sv*sigma_vt/sigma_st, with
  NetworkX's rescaling;
* closeness and harmonic against Floyd-Warshall distances (incoming, d(v, u), when directed);
* iterative measures: Expected is the LIMIT (the model run to tolerance 1e-15 or 1e-13), checked
  against a dense numpy/scipy solve (eigenvector: the Perron vector of A^T when the dominant
  eigenvalue is simple; Katz: (I - alpha A^T)^-1 beta 1; PageRank: the linear system of the
  Google matrix; HITS: principal singular vectors of A when sigma_1 is simple); and the model run
  with the row's parameters (defaults otherwise) must lie within the row's Tol of it;
* NetworkX 3.7 on every case it accepts with the same semantics (simple graphs; PageRank and
  closeness also multigraphs; eigenvector, Katz and PageRank on undirected graphs only without
  self-loops, since NetworkX counts an undirected loop once in A), within Tol; `nil` rows must make
  NetworkX raise PowerIterationFailedConvergence when it runs the same iteration.
"""

import heapq
import math
import re
import sys
from pathlib import Path

import networkx as nx
import numpy as np
import scipy.linalg as sla

HERE = Path(__file__).resolve().parent
CASES = HERE / "cases.md"


class Trap(Exception):
    pass


def vtok(s):
    s = s.strip()
    return int(s) if re.fullmatch(r"-?\d+", s) else s


def split_top(s, sep=","):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == sep and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    out.append(cur)
    return [x.strip() for x in out if x.strip()]


def items(s):
    res = []
    for t in split_top(s):
        m = re.fullmatch(r"(-?\d+)\.\.(-?\d+)", t)
        res.extend(range(int(m.group(1)), int(m.group(2)) + 1) if m else [vtok(t)])
    return res


MASK = (1 << 64) - 1


def lcg_edges(n, m, seed):
    """m pseudo-random non-loop pairs over 0..<n (api.md / cases.md `lcg`)."""
    x, out = seed & MASK, []
    def step():
        nonlocal x
        x = (x * 6364136223846793005 + 1442695040888963407) & MASK
        return (x >> 33) % n
    while len(out) < m:
        u, v = step(), step()
        if u != v:
            out.append((u, v))
    return out


def nx_named(name):
    g = getattr(nx, name + "_graph")()
    return list(g.nodes), list(g.edges())


def edge_tokens(s):
    """(listed vertices from generators, [(a, b)]) for one edge list."""
    out, extra = [], []
    for t in split_top(s):
        if t.startswith("P("):
            vs = items(t[2:-1])
            out += list(zip(vs, vs[1:]))
        elif t.startswith("C("):
            vs = items(t[2:-1])
            out += list(zip(vs, vs[1:] + vs[:1]))
        elif t.startswith("S("):
            c, rest = t[2:-1].split(";")
            out += [(vtok(c), x) for x in items(rest)]
        elif t.startswith("KB("):
            a, b = t[3:-1].split(";")
            out += [(x, y) for x in items(a) for y in items(b)]
        elif t.startswith("K("):
            vs = items(t[2:-1])
            if len(vs) == 1:
                vs = list(range(vs[0]))
            out += [(vs[i], vs[j]) for i in range(len(vs)) for j in range(i + 1, len(vs))]
        elif t.startswith("grid("):
            r, c = (int(x) for x in t[5:-1].split(","))
            extra += list(range(r * c))
            for i in range(r):
                for j in range(c):
                    v = i * c + j
                    if j + 1 < c:
                        out.append((v, v + 1))
                    if i + 1 < r:
                        out.append((v, v + c))
        elif t.startswith("kary("):
            n, k = (int(x) for x in t[5:-1].split(","))
            out += [(i, c) for i in range(n) for c in range(k * i + 1, k * i + k + 1) if c < n]
        elif t.startswith("lcg("):
            n, m, seed = (int(x) for x in t[4:-1].split(","))
            out += lcg_edges(n, m, seed)
        elif t.startswith("nx("):
            nodes, es = nx_named(t[3:-1])
            extra += nodes
            out += es
        else:
            m = re.fullmatch(r"(-?\w+)\s*(-|>)\s*(-?\w+)", t)
            assert m, f"bad edge token {t!r}"
            out.append((vtok(m.group(1)), vtok(m.group(3))))
    return extra, out


class G:
    """A graph as api.md sees it: vertices in order, edge ends by position, rows."""

    def __init__(self, directed, vertices, ends, rev=False):
        self.directed, self.vertices, self.ends = directed, vertices, ends
        self.n, self.m = len(vertices), len(ends)
        rows = [[] for _ in range(self.n)]
        for e, (a, b) in enumerate(ends):
            if directed:
                rows[a].append((b, e))
            else:
                rows[a].append((b, e))
                rows[b].append((a, e))  # a self-loop: twice in its row
        if rev:
            rows = [r[::-1] for r in rows]
        self.rows = rows

    def directed_view(self):
        """graph.directed: arc 2p forward, 2p+1 reversed; rows from incidentEdges order."""
        assert not self.directed
        ends = []
        for a, b in self.ends:
            ends += [(a, b), (b, a)]
        g = G(True, self.vertices, ends)
        rows = [[] for _ in range(self.n)]
        for v in range(self.n):
            loops = []
            for (w, e) in self.rows[v]:
                a, b = self.ends[e]
                if a == b:  # the loop's forward arc first, reversed at its second listing
                    rows[v].append((v, 2 * e + (1 if e in loops else 0)))
                    loops.append(e)
                else:
                    rows[v].append((w, 2 * e + (0 if a == v else 1)))
        g.rows = rows
        g.base_edge = lambda arc: arc // 2
        return g

    def undirected_view(self):
        assert self.directed
        return G(False, self.vertices, self.ends)


def parse_graph(cell):
    cell = cell.strip().strip("`")
    rev = False
    if cell.endswith("~rev"):
        rev, cell = True, cell[: -len("~rev")].strip()
    kind, rest = cell.split(":", 1)
    m = re.match(r"\s*\[(.*?)\]\s*(.*)", rest)
    listed, es = (m.group(1), m.group(2)) if m else ("", rest)
    extra, pairs = edge_tokens(es)
    vs, seen = [], set()
    for v in items(listed) + extra + [x for p in pairs for x in p]:
        if v not in seen:
            seen.add(v)
            vs.append(v)
    num = {v: i for i, v in enumerate(vs)}
    return G(kind.strip() == "D", vs, [(num[a], num[b]) for a, b in pairs], rev)


def parse_weights(s, m):
    s = s.strip()
    if s.startswith("["):
        out = []
        for x in split_top(s[1:-1]):
            out.append(float(x) if x in ("nan", "inf") or "." in x else int(x))
        assert len(out) == m, f"{len(out)} weights for {m} edges"
        return out
    mm = re.fullmatch(r"e%(\d+)\+(\d+)", s)
    if mm:
        k, c = int(mm.group(1)), int(mm.group(2))
        return [e % k + c for e in range(m)]
    return [float(s) if "." in s else int(s)] * m


# --------------------------------------------------------------------------------------------
# The model (api.md, index space)
# --------------------------------------------------------------------------------------------


def weights_of(g, w, positive=False, finite=False):
    """Read every weight once in position order and check it (api.md: Weights)."""
    if w is None:
        return [1] * g.m
    for x in w:
        if x != x or x < 0 or (positive and x == 0) or (finite and math.isinf(x)):
            raise Trap()
    return w


def edge_of(g, e):
    return g.base_edge(e) if hasattr(g, "base_edge") else e


def search_rows(g, reverse):
    """Rows for searches: self-loops dropped; reversed (incoming) for directed closeness."""
    rows = [[] for _ in range(g.n)]
    for v in range(g.n):
        for (t, e) in g.rows[v]:
            if t == v:
                continue
            if reverse and g.directed:
                rows[t].append((v, e))
            else:
                rows[v].append((t, e))
    return rows


def sssp(rows, s, wt):
    """dist list (None unreachable); Dijkstra when wt else BFS."""
    n = len(rows)
    dist = [None] * n
    dist[s] = 0
    if wt is None:
        q = [s]
        for v in q:
            for t, e in rows[v]:
                if dist[t] is None:
                    dist[t] = dist[v] + 1
                    q.append(t)
        return dist
    h, done = [(0, s)], [False] * n
    while h:
        d, v = heapq.heappop(h)
        if done[v]:
            continue
        done[v] = True
        for t, e in rows[v]:
            nd = d + wt[edge_of_rows(e)]
            if dist[t] is None or nd < dist[t]:
                dist[t] = nd
                heapq.heappush(h, (nd, t))
    return dist


EDGE_MAP = [lambda e: e]


def edge_of_rows(e):
    return EDGE_MAP[0](e)


def degree_model(g, kind):
    n = g.n
    if n == 0:
        return []
    if n == 1:
        return [1.0]
    out = [len(g.rows[v]) for v in range(n)]
    inn = [0] * n
    if g.directed:
        for v in range(n):
            for t, e in g.rows[v]:
                inn[t] += 1
    d = {"degree": [o + i for o, i in zip(out, inn)] if g.directed else out, "in": inn, "out": out}[kind]
    return [x / (n - 1) for x in d]


def closeness_model(g, w, wf, only=None, harmonic=False):
    wt = None if w is None else weights_of(g, w)
    rows = search_rows(g, reverse=True)
    res = []
    for u in range(g.n) if only is None else [only]:
        dist = sssp(rows, u, wt)
        if harmonic:
            res.append(float(sum(1 / d for d in dist if d is not None and d != 0)))
            continue
        reach = [d for d in dist if d is not None]
        tot, r = sum(reach), len(reach)
        if tot > 0 and g.n > 1:
            c = (r - 1) / tot
            if wf:
                c *= (r - 1) / (g.n - 1)
        else:
            c = 0.0
        res.append(float(c))
    return res if only is None else res[0]


def rescale(b, n, normalized, endpoints, directed):
    if normalized:
        if endpoints:
            scale = None if n < 2 else 1 / (n * (n - 1))
        else:
            scale = None if n <= 2 else 1 / ((n - 1) * (n - 2))
    else:
        scale = None if directed else 0.5
    return [float(x * scale) if scale is not None else float(x) for x in b]


def betweenness_model(g, w, normalized, endpoints):
    """Brandes, successor-side accumulation, edge-path counting, exact distance equality."""
    wt = None if w is None else weights_of(g, w, positive=True)
    rows = search_rows(g, reverse=False)
    n = g.n
    bc = [0.0] * n
    for s in range(n):
        sigma = [0.0] * n
        dist = [None] * n
        sigma[s], dist[s] = 1.0, 0
        order = []
        if wt is None:
            q = [s]
            for v in q:
                order.append(v)
                for t, e in rows[v]:
                    if dist[t] is None:
                        dist[t] = dist[v] + 1
                        q.append(t)
                    if dist[t] == dist[v] + 1:
                        sigma[t] += sigma[v]
        else:
            h, done = [(0, s)], [False] * n
            while h:
                d, v = heapq.heappop(h)
                if done[v] or d != dist[v]:
                    continue
                done[v] = True
                order.append(v)
                for t, e in rows[v]:
                    nd = d + wt[edge_of_rows(e)]
                    if dist[t] is None or nd < dist[t]:
                        dist[t] = nd
                        sigma[t] = sigma[v]
                        heapq.heappush(h, (nd, t))
                    elif nd == dist[t]:
                        sigma[t] += sigma[v]
        delta = [0.0] * n
        for v in reversed(order):
            for t, e in rows[v]:
                step = 1 if wt is None else wt[edge_of_rows(e)]
                if dist[t] is not None and dist[t] == dist[v] + step:
                    delta[v] += sigma[v] / sigma[t] * (1 + delta[t])
            if v != s:
                bc[v] += delta[v] + (1 if endpoints else 0)
        if endpoints:
            bc[s] += len(order) - 1
    return rescale(bc, n, normalized, endpoints, g.directed)


def matrix(g, w):
    """A[v][t] = sum of weights of the slots v -> t (an undirected loop twice)."""
    wt = [1.0] * g.m if w is None else [float(x) for x in weights_of(g, w, finite=True)]
    A = [[0.0] * g.n for _ in range(g.n)]
    rows = []
    for v in range(g.n):
        r = []
        for t, e in g.rows[v]:
            r.append((t, wt[edge_of_rows(e)]))
            A[v][t] += wt[edge_of_rows(e)]
        rows.append(r)
    return A, rows


def pull(rows, x, n):
    """y[t] = sum over slots v -> t of x[v] * w, in increasing v, then row order."""
    y = [0.0] * n
    for v in range(n):
        for t, wv in rows[v]:
            y[t] += x[v] * wv
    return y


def eigenvector_model(g, w, tol=1e-6, maxit=100):
    n = g.n
    if n == 0:
        return []
    _, rows = matrix(g, w)
    x = [1.0 / n] * n
    for _ in range(maxit):
        y = pull(rows, x, n)
        y = [a + b for a, b in zip(x, y)]
        norm = math.sqrt(sum(v * v for v in y)) or 1.0
        y = [v / norm for v in y]
        err = sum(abs(a - b) for a, b in zip(y, x))
        x = y
        if err < n * tol:
            return x
    return None


def katz_model(g, w, alpha=0.1, beta=1.0, normalized=True, tol=1e-6, maxit=1000):
    n = g.n
    if n == 0:
        return []
    _, rows = matrix(g, w)
    x = [0.0] * n
    for _ in range(maxit):
        y = [alpha * v + beta for v in pull(rows, x, n)]
        err = sum(abs(a - b) for a, b in zip(y, x))
        x = y
        if err < n * tol:
            if normalized:
                s = math.sqrt(sum(v * v for v in x))
                x = [v / s for v in x]
            return x
    return None


def personal(n, p):
    if p is None:
        return [1.0 / n] * n
    for v in p:
        if v != v or v < 0 or math.isinf(v):
            raise Trap()
    s = sum(p)
    if s == 0:
        raise Trap()
    return [v / s for v in p]


def pagerank_model(g, w, d=0.85, p=None, tol=1e-6, maxit=100):
    n = g.n
    if n == 0:
        return []
    _, rows = matrix(g, w)
    pv = personal(n, p)
    out = [sum(wv for _, wv in r) for r in rows]
    nrows = [[(t, wv / out[v]) for t, wv in rows[v]] if out[v] != 0 else [] for v in range(n)]
    dangling = [v for v in range(n) if out[v] == 0]
    x = [1.0 / n] * n
    for _ in range(maxit):
        y = pull(nrows, x, n)
        ds = sum(x[v] for v in dangling)
        y = [d * (y[i] + ds * pv[i]) + (1 - d) * pv[i] for i in range(n)]
        err = sum(abs(a - b) for a, b in zip(y, x))
        x = y
        if err < n * tol:
            return x
    return None


def hits_model(g, w, tol=1e-8, maxit=100):
    n = g.n
    if n == 0:
        return [], []
    _, rows = matrix(g, w)
    if all(not r for r in rows) or all(wv == 0 for r in rows for _, wv in r):
        return [1.0 / n] * n, [1.0 / n] * n
    h = [1.0 / n] * n
    for _ in range(maxit):
        a = pull(rows, h, n)
        hn = [sum(wv * a[t] for t, wv in rows[v]) for v in range(n)]
        mh, ma = max(hn), max(a)
        hn = [v / mh for v in hn]
        a = [v / ma for v in a]
        err = sum(abs(p - q) for p, q in zip(hn, h))
        h = hn
        if err < n * tol:
            sh, sa = sum(h), sum(a)
            return [v / sh for v in h], [v / sa for v in a]
    return None


# --------------------------------------------------------------------------------------------
# Independent checks
# --------------------------------------------------------------------------------------------


def floyd(g, wt, reverse):
    n, INF = g.n, float("inf")
    D = [[INF] * n for _ in range(n)]
    for i in range(n):
        D[i][i] = 0
    for e, (a, b) in enumerate(g.ends):
        if a == b:
            continue
        c = 1 if wt is None else wt[e]
        pairs = [(a, b)] if g.directed else [(a, b), (b, a)]
        for x, y in pairs:
            D[x][y] = min(D[x][y], c)
    for k in range(n):
        for i in range(n):
            for j in range(n):
                if D[i][k] + D[k][j] < D[i][j]:
                    D[i][j] = D[i][k] + D[k][j]
    return D


def brute_closeness(g, w, wf, harmonic):
    D = floyd(g, w, False)
    n, res = g.n, []
    for u in range(n):
        ds = [D[v][u] for v in range(n)]  # incoming: from v to u
        if harmonic:
            res.append(sum(1 / d for d in ds if 0 < d < float("inf")))
            continue
        fin = [d for d in ds if d < float("inf")]
        tot, r = sum(fin), len(fin)
        c = 0.0
        if tot > 0 and n > 1:
            c = (r - 1) / tot * ((r - 1) / (n - 1) if wf else 1)
        res.append(c)
    return res


def brute_betweenness(g, w, normalized, endpoints):
    """BC(v) = sum over ordered s != v != t of sigma_sv sigma_vt / sigma_st, edge sequences."""
    n = g.n
    D = floyd(g, w, False)
    arcs = []
    for e, (a, b) in enumerate(g.ends):
        if a == b:
            continue
        c = 1 if w is None else w[e]
        arcs.append((a, b, c))
        if not g.directed:
            arcs.append((b, a, c))
    sig = [[0] * n for _ in range(n)]
    for s in range(n):
        order = sorted((v for v in range(n) if D[s][v] < float("inf")), key=lambda v: D[s][v])
        sig[s][s] = 1
        for v in order:
            for a, b, c in arcs:
                if b == v and a != v and D[s][a] + c == D[s][v] and D[s][a] < D[s][v]:
                    sig[s][v] += sig[s][a]
    bc = [0.0] * n
    for s in range(n):
        for t in range(n):
            if s == t or D[s][t] == float("inf"):
                continue
            if endpoints:
                bc[s] += 1
                bc[t] += 1
            for v in range(n):
                if v in (s, t):
                    continue
                if D[s][v] + D[v][t] == D[s][t]:
                    bc[v] += sig[s][v] * sig[v][t] / sig[s][t]
    return rescale(bc, n, normalized, endpoints, g.directed)


def eig_limit(g, w):
    return eigenvector_model(g, w, tol=1e-15, maxit=2_000_000)


def check_eig_numpy(g, w, x):
    A = np.array(matrix(g, w)[0])
    M = A.T + np.eye(g.n)
    vals, vecs = np.linalg.eig(M)
    k = int(np.argmax(vals.real))
    others = [abs(v) for i, v in enumerate(vals) if i != k]
    if others and max(others) > vals[k].real - 1e-9:
        return  # not simple: the limit depends on the start vector; the model is the reference
    v = np.abs(vecs[:, k].real)
    v /= np.linalg.norm(v)
    assert np.allclose(v, x, atol=1e-9), (v, x)


def katz_exact(g, w, alpha, beta, normalized):
    A = np.array(matrix(g, w)[0])
    x = np.linalg.solve(np.eye(g.n) - alpha * A.T, beta * np.ones(g.n))
    return list(x / np.linalg.norm(x)) if normalized else list(x)


def pagerank_exact(g, w, d, p):
    n = g.n
    A = np.array(matrix(g, w)[0])
    out = A.sum(axis=1)
    pv = np.array(personal(n, p))
    P = np.zeros((n, n))
    for v in range(n):
        P[v] = A[v] / out[v] if out[v] != 0 else pv
    x = np.linalg.solve(np.eye(n) - d * P.T, (1 - d) * pv)
    return list(x / x.sum())


def hits_exact(g, w):
    A = np.array(matrix(g, w)[0])
    U, S, Vt = np.linalg.svd(A)
    if len(S) > 1 and S[0] - S[1] < 1e-9:
        return None
    h, a = np.abs(U[:, 0]), np.abs(Vt[0])
    return list(h / h.sum()), list(a / a.sum())


def to_nx(g, w):
    simple = len({tuple(sorted(p)) if not g.directed else p for p in g.ends}) == g.m
    if g.directed:
        G_ = nx.DiGraph() if simple else nx.MultiDiGraph()
    else:
        G_ = nx.Graph() if simple else nx.MultiGraph()
    G_.add_nodes_from(range(g.n))
    for e, (a, b) in enumerate(g.ends):
        G_.add_edge(a, b, w=(1 if w is None else w[e]), weight=(1 if w is None else w[e]))
    loops = any(a == b for a, b in g.ends)
    return G_, simple, loops


# --------------------------------------------------------------------------------------------
# Ops
# --------------------------------------------------------------------------------------------


def parse_args(s):
    args = {}
    for part in split_top(s):
        k, v = part.split(":", 1)
        v = v.strip()
        if v in ("true", "false"):
            args[k.strip()] = v == "true"
        elif v.startswith("[") or v.startswith("e%"):
            args[k.strip()] = v
        else:
            args[k.strip()] = float(v) if re.search(r"[.e]", v) else int(v)
    return args


def parse_op(op):
    op = op.strip().strip("`")
    view = None
    m = re.match(r"(directed|undirected)\s*>\s*(.*)", op)
    if m:
        view, op = m.group(1), m.group(2)
    part = None
    m = re.fullmatch(r"(.*)\.(hubs|authorities)", op)
    if m:
        op, part = m.group(1), m.group(2)
    m = re.fullmatch(r"(\w+)(?:\((.*)\))?", op)
    return view, m.group(1), parse_args(m.group(2) or ""), part


def run(g, name, a, part, defaults=False):
    """The model; for iterative measures `defaults=False` gives the limit."""
    w = parse_weights(a["weight"], g.m) if "weight" in a else None
    p = [float(x) for x in split_top(a["personalization"][1:-1])] if "personalization" in a else None
    tol = a.get("tolerance")
    mi = a.get("maxIterations")
    if name in ("degreeCentrality", "inDegreeCentrality", "outDegreeCentrality"):
        return degree_model(g, {"degreeCentrality": "degree", "inDegreeCentrality": "in", "outDegreeCentrality": "out"}[name])
    if name == "closenessCentrality":
        of = a.get("of")
        return closeness_model(g, w, a.get("wfImproved", True), only=None if of is None else g.vertices.index(of))
    if name == "harmonicCentrality":
        of = a.get("of")
        return closeness_model(g, w, False, only=None if of is None else g.vertices.index(of), harmonic=True)
    if name == "betweennessCentrality":
        return betweenness_model(g, w, a.get("normalized", True), a.get("endpoints", False))
    if name == "eigenvectorCentrality":
        if not defaults:
            return eig_limit(g, w)
        return eigenvector_model(g, w, tol or 1e-6, mi or 100)
    if name == "katzCentrality":
        kw = dict(alpha=a.get("alpha", 0.1), beta=a.get("beta", 1.0), normalized=a.get("normalized", True))
        if not defaults:
            return katz_model(g, w, tol=1e-15, maxit=2_000_000, **kw)
        return katz_model(g, w, tol=tol or 1e-6, maxit=mi or 1000, **kw)
    if name == "pageRank":
        d = a.get("dampingFactor", 0.85)
        if not defaults:
            return pagerank_model(g, w, d, p, tol=1e-15, maxit=2_000_000)
        return pagerank_model(g, w, d, p, tol=tol or 1e-6, maxit=mi or 100)
    if name == "hits":
        r = hits_model(g, w, 1e-15, 2_000_000) if not defaults else hits_model(g, w, tol or 1e-8, mi or 100)
        if r is None:
            return None
        return r[0] if part == "hubs" else r[1]
    raise ValueError(name)


ITERATIVE = {"eigenvectorCentrality", "katzCentrality", "pageRank", "hits"}


def fmt(x):
    if x is None:
        return "nil"
    if isinstance(x, list):
        return "[" + ", ".join(f"{(0.0 if abs(v) < 1e-13 else v):.12g}" for v in x) + "]"
    return f"#{x:.12g}"


def parse_expected(s):
    s = s.strip().strip("`")
    if s in ("nil", "trap"):
        return s
    if s.startswith("#"):
        return float(s[1:])
    return [float(x) for x in split_top(s[1:-1])]


def close(a, b, tol):
    if isinstance(a, list):
        return isinstance(b, list) and len(a) == len(b) and all(close(x, y, tol) for x, y in zip(a, b))
    return abs(a - b) <= tol * max(1.0, abs(b))


def evaluate(gcell, op):
    g = parse_graph(gcell)
    view, name, a, part = parse_op(op)
    if view == "directed":
        g = g.directed_view()
    elif view == "undirected":
        g = g.undirected_view()
    try:
        exact = run(g, name, a, part)
        dflt = run(g, name, a, part, defaults=True) if name in ITERATIVE else exact
    except Trap:
        return g, name, a, part, "trap", "trap"
    if name in ITERATIVE and dflt is None:
        exact = None  # the documented result is nil; no limit is claimed
    return g, name, a, part, exact, dflt


def nx_value(g, name, a, part):
    """NetworkX's answer when it shares the semantics, else NotImplemented."""
    w = parse_weights(a["weight"], g.m) if "weight" in a else None
    G_, simple, loops = to_nx(g, w)
    wk = "w" if w is not None else None
    nodes = list(range(g.n))
    vec = lambda d: [float(d[v]) for v in nodes]
    if name == "degreeCentrality":
        return vec(nx.degree_centrality(G_))
    if name == "inDegreeCentrality":
        return vec(nx.in_degree_centrality(G_))
    if name == "outDegreeCentrality":
        return vec(nx.out_degree_centrality(G_))
    if name == "closenessCentrality":
        if "of" in a:
            return float(nx.closeness_centrality(G_, u=g.vertices.index(a["of"]), distance=wk, wf_improved=a.get("wfImproved", True)))
        return vec(nx.closeness_centrality(G_, distance=wk, wf_improved=a.get("wfImproved", True)))
    if name == "harmonicCentrality":
        if "of" in a:
            return float(nx.harmonic_centrality(G_, nbunch=[g.vertices.index(a["of"])], distance=wk)[g.vertices.index(a["of"])])
        return vec(nx.harmonic_centrality(G_, distance=wk))
    if name == "betweennessCentrality":
        if not simple or (w is not None and any(x == 0 for x in w)):
            return NotImplemented
        return vec(nx.betweenness_centrality(G_, weight=wk, normalized=a.get("normalized", True), endpoints=a.get("endpoints", False)))
    pr = name in ("pageRank",)
    if g.n == 0 and name == "eigenvectorCentrality":
        return NotImplemented  # NetworkX raises NetworkXPointlessConcept
    if loops and not g.directed:
        return NotImplemented
    if not simple and not pr and name != "hits":
        return NotImplemented
    tol, mi = a.get("tolerance"), a.get("maxIterations")
    if name == "eigenvectorCentrality":
        return vec(nx.eigenvector_centrality(G_, weight=wk, tol=tol or 1e-6, max_iter=mi or 100))
    if name == "katzCentrality":
        return vec(nx.katz_centrality(G_, weight=wk, alpha=a.get("alpha", 0.1), beta=a.get("beta", 1.0),
                                      normalized=a.get("normalized", True), tol=tol or 1e-6, max_iter=mi or 1000))
    if name == "pageRank":
        p = [float(x) for x in split_top(a["personalization"][1:-1])] if "personalization" in a else None
        return vec(nx.pagerank(G_, alpha=a.get("dampingFactor", 0.85), weight=wk or "w",
                               personalization=None if p is None else dict(enumerate(p)),
                               tol=tol or 1e-6, max_iter=mi or 100))
    if name == "hits":
        if g.m == 0 or hits_exact(g, w) is None:
            return NotImplemented
        H, Au = nx.hits(G_)
        return vec(H if part == "hubs" else Au)
    return NotImplemented


def independent(g, name, a, part, exact):
    """Brute force / dense linear algebra for the same value; None when not applicable."""
    w = parse_weights(a["weight"], g.m) if "weight" in a else None
    if name == "closenessCentrality" or name == "harmonicCentrality":
        r = brute_closeness(g, w, a.get("wfImproved", True), name == "harmonicCentrality")
        return r[g.vertices.index(a["of"])] if "of" in a else r
    if name == "betweennessCentrality":
        return brute_betweenness(g, w, a.get("normalized", True), a.get("endpoints", False))
    if exact is None or g.n == 0:
        return None
    if name == "eigenvectorCentrality":
        check_eig_numpy(g, w, exact)
        return None
    if name == "katzCentrality":
        return katz_exact(g, w, a.get("alpha", 0.1), a.get("beta", 1.0), a.get("normalized", True))
    if name == "pageRank":
        p = [float(x) for x in split_top(a["personalization"][1:-1])] if "personalization" in a else None
        d = a.get("dampingFactor", 0.85)
        return pagerank_exact(g, w, d, p) if d < 1 else None
    if name == "hits":
        if g.m == 0:
            return None
        r = hits_exact(g, w)
        return None if r is None else (r[0] if part == "hubs" else r[1])
    return None


def main():
    fill = "--fill" in sys.argv
    lines = CASES.read_text().splitlines()
    out, n_cases, problems, ids = [], 0, [], set()
    for line in lines:
        m = re.match(r"\| (CE-\d+) \| (.*?) \| (.*?) \| (.*?) \| (.*?) \|(.*)$", line)
        if not m:
            out.append(line)
            continue
        cid, gcell, op, expc, tolc, rest = m.groups()
        assert cid not in ids, cid
        ids.add(cid)
        n_cases += 1
        g, name, a, part, exact, dflt = evaluate(gcell, op)
        tol = 1e-11 if tolc.strip() == "exact" else float(tolc)
        if expc.strip() == "?" and fill:
            expc = "`" + (exact if exact == "trap" else fmt(exact)) + "`"
            line = f"| {cid} | {gcell} | {op} | {expc} | {tolc} |{rest}"
        out.append(line)
        exp = parse_expected(expc) if expc.strip() != "?" else None
        if exp is None:
            problems.append(f"{cid}: unfilled")
            continue
        if exp in ("trap", "nil") or exact in ("trap", None):
            got = "trap" if exact == "trap" else "nil" if exact is None else exact
            if got != exp:
                problems.append(f"{cid}: expected {exp}, model {got}")
            if exp == "nil" and name in ("eigenvectorCentrality", "katzCentrality", "pageRank"):
                try:
                    nx_value(g, name, a, part)
                    problems.append(f"{cid}: NetworkX converged where the model says nil")
                except nx.PowerIterationFailedConvergence:
                    pass
            continue
        if not close(exact, exp, 1e-11):
            problems.append(f"{cid}: catalog {exp} != model {exact}")
        if name in ITERATIVE and not close(dflt, exp, tol):
            problems.append(f"{cid}: parameters' result {dflt} not within {tol} of the limit")
        ind = independent(g, name, a, part, exact)
        if ind is not None and not close(ind, exp, max(tol, 1e-9)):
            problems.append(f"{cid}: independent {ind} != {exp}")
        try:
            nv = nx_value(g, name, a, part)
        except nx.PowerIterationFailedConvergence:
            problems.append(f"{cid}: NetworkX failed to converge")
            continue
        if nv is not NotImplemented and not close(nv, exp, max(tol, 1e-9)):
            problems.append(f"{cid}: NetworkX {nv} != {exp}")
    if fill:
        CASES.write_text("\n".join(out) + "\n")
    for p in problems:
        print(p)
    print(f"{n_cases} cases")
    if not problems:
        print("all values agree")
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
