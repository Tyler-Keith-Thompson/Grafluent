"""Independent reference for the Distances module (catalog cases.md, DI-...).

Run:  uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3 Tests/Catalogs/Distances/ref.py
      (scipy is optional: without it the scipy cross-check is skipped and says so)
      ... python3 ref.py --fill         rewrite '?' Expected cells of cases.md with computed values
      ... python3 ref.py --emit DI-101  print the computed value of one case

Every value is computed by the model of api.md written here in index space, the way the Swift
implementation will run it (rows in `outEdges` / `incidentEdges` order, a self-loop twice in an
undirected row; breadth-first search or Dijkstra from every vertex; Takes–Kosters bounding for
the undirected unweighted extrema), and then checked independently:

* brute force from the definitions: all-pairs distances by Floyd–Warshall over the edge list;
  the lexicographically least diametral pair for diameterPath; every shortest path counted to
  pin weighted paths only where they are unique;
* the bounding model against the all-pairs model on every undirected unweighted case, in all
  five modes (diameter, radius, center, periphery, eccentricities);
* NetworkX 3.7 (MultiGraph / MultiDiGraph with nodes in `vertices` order and weight attribute
  "w"): eccentricity (all, and per vertex), radius, diameter, center, periphery, each with
  usebounds=True as well on undirected graphs, centroid (3.7's name for barycenter),
  wiener_index, average_shortest_path_length, density, shortest_path_length; and that NetworkX
  raises exactly where api.md answers nil (not connected) or where it raises on the null graph;
* scipy 1.18.1 `scipy.sparse.csgraph.shortest_path` (parallel edges reduced to the lightest by
  hand: a COO → CSR conversion would add them), whose infinite entries give the JGraphT / Boost
  semantics api.md adopts for unreachable vertices (nil = infinity, center/periphery by equality);
* trees: a case whose Notes cite `= TA-nnn` must carry exactly the value of that row of
  ../TreeAlgorithms/cases.md (same source, same op after `Tree : `).

Cases with more than BIG vertices skip all-pairs work: their values come from the bounding
model where that is fast (paths, stars) and from closed forms (CLOSED below).
"""

import heapq
import math
import re
import sys
from pathlib import Path

import networkx as nx

try:
    import numpy as np
    import scipy.sparse as sparse
    from scipy.sparse.csgraph import shortest_path as sp_shortest_path

    HAVE_SCIPY = True
except ImportError:  # pragma: no cover
    HAVE_SCIPY = False

HERE = Path(__file__).resolve().parent
CASES = HERE / "cases.md"
TA_CASES = HERE.parent / "TreeAlgorithms" / "cases.md"
BIG = 3000
NX_LIMIT = 400


class Trap(Exception):
    pass


# --------------------------------------------------------------------------------------------
# Parsing
# --------------------------------------------------------------------------------------------


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
    listed, es = m.group(1), m.group(2)
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


def check_weights(w):
    for x in w:
        if x != x or x < 0:
            raise Trap()


def search(g, s, w):
    """Distances from s (None = unreachable), by BFS (w None) or Dijkstra over the rows."""
    n = g.n
    dist = [None] * n
    dist[s] = 0
    if w is None:
        queue, head = [s], 0
        while head < len(queue):
            u = queue[head]
            head += 1
            for v, _ in g.rows[u]:
                if dist[v] is None:
                    dist[v] = dist[u] + 1
                    queue.append(v)
        return dist
    done = [False] * n
    heap = [(0, s)]
    while heap:
        d, u = heapq.heappop(heap)
        if done[u] or d != dist[u]:
            continue
        done[u] = True
        for v, e in g.rows[u]:
            c = d + w[e]
            if dist[v] is None or c < dist[v]:
                dist[v] = c
                heapq.heappush(heap, (c, v))
    return dist


def all_distances(g, w):
    return [search(g, s, w) for s in range(g.n)]


def eccentricities_model(D):
    return [None if any(x is None for x in row) else max(row) for row in D]


def extrema(ecc):
    """radius, diameter, center, periphery (as vertex numbers) by api.md's rules."""
    if not ecc:
        return None, None, [], []
    finite = [x for x in ecc if x is not None]
    radius = min(finite) if finite else None
    diameter = None if len(finite) < len(ecc) else max(ecc)
    center = [i for i, x in enumerate(ecc) if x == radius]
    periphery = [i for i, x in enumerate(ecc) if x == diameter]
    return radius, diameter, center, periphery


def totals_model(D):
    return [None if any(x is None for x in row) else sum(row) for row in D]


def centroid_model(D):
    t = totals_model(D)
    if not t:
        return []
    finite = [x for x in t if x is not None]
    least = min(finite) if finite else None
    return [i for i, x in enumerate(t) if x == least]


def wiener_model(g, D):
    total = 0
    for u in range(g.n):
        for v in range(g.n):
            if u == v or (not g.directed and v < u):
                continue
            if D[u][v] is None:
                return None
            total += D[u][v]
    return total


def average_model(g, D, weighted):
    if g.n == 0:
        return None
    if g.n == 1:
        return 0.0
    wi = wiener_model(g, D)
    if wi is None:
        return None
    pairs = g.n * (g.n - 1) if g.directed else g.n * (g.n - 1) // 2
    return wi / pairs


def density_model(g):
    if g.n <= 1:
        return 0.0
    return (1 if g.directed else 2) * g.m / (g.n * (g.n - 1))


def diameter_path_model(g, D, w):
    """(vertex numbers, edge positions, distance) or None, by api.md's rule."""
    if g.n == 0:
        return None
    ecc = eccentricities_model(D)
    _, diameter, _, periphery = extrema(ecc)
    if diameter is None:
        return None
    u = periphery[0]
    if w is None:
        # ShortestPaths' BFS: parent = first discoverer, through its first such out-edge.
        parent, pedge, dist = [-2] * g.n, [None] * g.n, [0] * g.n
        parent[u] = -1
        queue, head = [u], 0
        while head < len(queue):
            x = queue[head]
            head += 1
            for y, e in g.rows[x]:
                if parent[y] == -2:
                    parent[y], pedge[y], dist[y] = x, e, dist[x] + 1
                    queue.append(y)
        v = max(range(g.n), key=lambda i: (dist[i], -i))
        vs, es = [v], []
        while parent[vs[-1]] >= 0:
            es.append(pedge[vs[-1]])
            vs.append(parent[vs[-1]])
        return vs[::-1], es[::-1], dist[v]
    dist = search(g, u, w)
    best = max(dist)
    v = dist.index(best)
    # Every shortest u→v path, by walking tight arcs; pinned only when there is one.
    paths = []
    stack = [(u, [u], [])]
    while stack:
        x, vs, es = stack.pop()
        if x == v:
            paths.append((vs, es))
            if len(paths) > 1:
                break
            continue
        for y, e in g.rows[x]:
            if y not in vs and dist[x] + w[e] == dist[y]:
                stack.append((y, vs + [y], es + [e]))
    if len(paths) != 1:
        raise AssertionError("weighted diameterPath is not unique: pick another case")
    return paths[0][0], paths[0][1], best


def bounding(g, mode):
    """Takes–Kosters bounding over BFS (undirected, unweighted, connected), api.md's version.

    Returns (value, number of searches). The value is None for a disconnected graph."""
    n = g.n
    deg = [len(r) for r in g.rows]
    lower, upper = [0] * n, [math.inf] * n
    candidates = list(range(n))
    searches = 0
    current = max(range(n), key=lambda i: (deg[i], -i))
    high = False
    minlower = minupper = math.inf
    maxlower = maxupper = 0
    while candidates:
        dist = search(g, current, None)
        searches += 1
        if any(x is None for x in dist):
            if mode == "eccentricities":
                return [None] * n, searches
            if mode in ("center", "periphery"):
                return list(range(n)), searches
            return None, searches
        e = max(dist)
        for i in candidates:
            d = dist[i]
            lower[i] = max(lower[i], d, e - d)
            upper[i] = min(upper[i], e + d)
            minlower, maxlower = min(minlower, lower[i]), max(maxlower, lower[i])
            minupper, maxupper = min(minupper, upper[i]), max(maxupper, upper[i])
        keep = []
        for i in candidates:
            if lower[i] == upper[i]:
                continue
            if mode == "diameter" and upper[i] <= maxlower and 2 * lower[i] >= maxupper:
                continue
            if mode == "radius" and lower[i] >= minupper and upper[i] + 1 <= 2 * minlower:
                continue
            if mode == "periphery" and upper[i] < maxlower and (maxlower == maxupper or lower[i] > maxupper):
                continue
            if mode == "center" and lower[i] > minupper and (minlower == minupper or upper[i] + 1 < 2 * minlower):
                continue
            keep.append(i)
        candidates = keep
        if not candidates:
            break
        high = not high
        if high:
            current = min(candidates, key=lambda i: (-upper[i], -deg[i], i))
        else:
            current = min(candidates, key=lambda i: (lower[i], -deg[i], i))
    if mode == "diameter":
        return maxlower, searches
    if mode == "radius":
        return minupper, searches
    if mode == "periphery":
        return [v for v in range(n) if lower[v] == maxlower], searches
    if mode == "center":
        return [v for v in range(n) if upper[v] == minupper], searches
    return lower, searches


# --------------------------------------------------------------------------------------------
# Formatting
# --------------------------------------------------------------------------------------------


def fnum(x):
    return repr(x) if isinstance(x, float) else str(x)


def fmt_value(x):
    return "nil" if x is None else "#" + fnum(x)


def fmt_vertices(g, idx):
    return "[" + ", ".join(str(g.vertices[i]) for i in idx) + "]"


def fmt_eccs(xs):
    return "[" + ", ".join("nil" if x is None else fnum(x) for x in xs) + "]"


def fmt_path(g, p, weighted, edge_map=None):
    if p is None:
        return "nil"
    vs, es, d = p
    s = fmt_vertices(g, vs) + "/[" + ", ".join(str(e) for e in es) + "]"
    return s + (" #" + fnum(d) if weighted else "")


# --------------------------------------------------------------------------------------------
# Evaluation
# --------------------------------------------------------------------------------------------

OP = re.compile(r"^(\w+)(?:\((.*)\))?$")


def parse_op(op):
    view = None
    if ">" in op:
        view, op = (x.strip() for x in op.split(">", 1))
    m = OP.fullmatch(op.strip())
    assert m, f"bad op {op!r}"
    name, args = m.group(1), m.group(2) or ""
    weight, of = None, None
    for a in split_top(args):
        k, v = (x.strip() for x in a.split(":", 1))
        if k == "weight":
            weight = v
        elif k == "of":
            of = vtok(v)
        else:
            raise AssertionError(f"bad argument {a!r}")
    return view, name, weight, of


def evaluate(graph_cell, op, check=True):
    g0 = parse_graph(graph_cell)
    view, name, wspec, of = parse_op(op)
    g = g0
    if view == "directed":
        g = g0.directed_view()
    elif view == "undirected":
        g = g0.undirected_view()
    elif view is not None:
        raise AssertionError(view)
    w = None
    if wspec is not None:
        w = parse_weights(wspec, g0.m)
        try:
            check_weights(w)
        except Trap:
            return "trap"
        if view == "directed":
            w = [w[a // 2] for a in range(g.m)]
    if name == "density":
        return fmt_value(density_model(g))
    if of is not None and of not in g.vertices:
        return "trap"
    big = g.n > BIG
    if big:
        return evaluate_big(g, name, w)
    D = all_distances(g, w)
    if check:
        cross_check(g, D, w)
    ecc = eccentricities_model(D)
    radius, diameter, center, periphery = extrema(ecc)
    if name == "eccentricities":
        return fmt_eccs(ecc)
    if name == "eccentricity":
        return fmt_value(ecc[g.vertices.index(of)])
    if name == "radius":
        return fmt_value(radius)
    if name == "diameter":
        return fmt_value(diameter)
    if name == "center":
        return fmt_vertices(g, center)
    if name == "periphery":
        return fmt_vertices(g, periphery)
    if name == "centroid":
        return fmt_vertices(g, centroid_model(D))
    if name == "wienerIndex":
        return fmt_value(wiener_model(g, D))
    if name == "averageShortestPathLength":
        return fmt_value(average_model(g, D, w is not None))
    if name == "diameterPath":
        assert view is None, "diameterPath on a view returns arc positions; not cataloged"
        p = diameter_path_model(g, D, w)
        if check and p is not None:
            check_path(g, D, w, p)
        return fmt_path(g, p, w is not None)
    raise AssertionError(f"unknown op {name}")


def evaluate_big(g, name, w):
    assert w is None and not g.directed, "big cases: undirected unweighted only"
    if name in ("diameter", "radius", "center", "periphery") and g.m == g.n - 1:
        value, searches = bounding(g, name)
        SEARCHES[(id(g), name)] = searches
        if name in ("center", "periphery"):
            return fmt_vertices(g, value)
        return fmt_value(value)
    raise LookupError("closed form")  # filled by CLOSED


SEARCHES = {}

# --------------------------------------------------------------------------------------------
# Cross-checks
# --------------------------------------------------------------------------------------------


def floyd(g, w):
    n = g.n
    INF = math.inf
    d = [[INF] * n for _ in range(n)]
    for i in range(n):
        d[i][i] = 0
    for e, (a, b) in enumerate(g.ends):
        x = 1 if w is None else w[e]
        if x < d[a][b]:
            d[a][b] = x
        if not g.directed and x < d[b][a]:
            d[b][a] = x
    for k in range(n):
        dk = d[k]
        for i in range(n):
            dik = d[i][k]
            if dik == INF:
                continue
            di = d[i]
            for j in range(n):
                if dik + dk[j] < di[j]:
                    di[j] = dik + dk[j]
    return [[None if x == INF else x for x in row] for row in d]


def to_nx(g, w):
    h = nx.MultiDiGraph() if g.directed else nx.MultiGraph()
    h.add_nodes_from(g.vertices)
    for e, (a, b) in enumerate(g.ends):
        h.add_edge(g.vertices[a], g.vertices[b], key=e, w=1 if w is None else w[e])
    return h


def raises(f):
    try:
        f()
        return False
    except (nx.NetworkXError, nx.NetworkXPointlessConcept, nx.NetworkXNoPath, ValueError):
        return True


def cross_check(g, D, w):
    n = g.n
    infinite = w is not None and any(isinstance(x, float) and math.isinf(x) for x in w)
    if n <= 200 and not infinite:
        assert floyd(g, w) == D, "BFS/Dijkstra model differs from Floyd–Warshall"
    ecc = eccentricities_model(D)
    radius, diameter, center, periphery = extrema(ecc)
    connected = n > 0 and all(x is not None for x in ecc)
    # Bounding against all pairs.
    if not g.directed and w is None and n > 0:
        for mode, want in (("diameter", diameter), ("radius", radius), ("center", center),
                           ("periphery", periphery), ("eccentricities", ecc)):
            got, _ = bounding(g, mode)
            assert got == want, f"bounding {mode}: {got} != {want}"
    # scipy: infinity semantics.
    if HAVE_SCIPY and n > 0 and not infinite:
        best = {}
        for e, (a, b) in enumerate(g.ends):
            if a == b:
                continue
            x = 1 if w is None else w[e]
            for p in ([(a, b)] if g.directed else [(a, b), (b, a)]):
                if p not in best or x < best[p]:
                    best[p] = x
        rows = [p[0] for p in best]
        cols = [p[1] for p in best]
        vals = [float(best[p]) for p in best]
        A = sparse.csr_array((np.array(vals, dtype=float), (np.array(rows, dtype=int), np.array(cols, dtype=int))), shape=(n, n))
        M = sp_shortest_path(A, method="D", directed=True, unweighted=w is None)
        S = [[None if math.isinf(x) else x for x in row] for row in M.tolist()]
        assert all(S[i][j] == D[i][j] for i in range(n) for j in range(n)), "scipy distances differ"
        se = M.max(axis=1)
        assert [None if math.isinf(x) else x for x in se.tolist()] == ecc
        sr, sd = se.min(), se.max()
        assert list(np.flatnonzero(se == sr)) == center, "scipy center"
        assert list(np.flatnonzero(se == sd)) == periphery, "scipy periphery"
        tot = M.sum(axis=1)
        assert list(np.flatnonzero(tot == tot.min())) == centroid_model(D), "scipy centroid"
    if n > NX_LIMIT:
        return
    h = to_nx(g, w)
    wk = None if w is None else "w"
    V = g.vertices
    if n == 0:
        assert raises(lambda: nx.eccentricity(h)) and raises(lambda: nx.diameter(h))
        assert raises(lambda: nx.wiener_index(h)) and raises(lambda: nx.average_shortest_path_length(h))
        assert nx.density(h) == 0
        return
    for i, v in enumerate(V):
        if ecc[i] is None:
            assert raises(lambda: nx.eccentricity(h, v=v, weight=wk)), f"nx eccentricity({v}) should raise"
        else:
            assert nx.eccentricity(h, v=v, weight=wk) == ecc[i], f"nx eccentricity({v})"
    if connected:
        assert nx.radius(h, weight=wk) == radius
        assert nx.diameter(h, weight=wk) == diameter
        assert nx.center(h, weight=wk) == [V[i] for i in center], "nx center order"
        assert nx.periphery(h, weight=wk) == [V[i] for i in periphery], "nx periphery order"
        if not g.directed:
            assert nx.radius(h, usebounds=True, weight=wk) == radius, "nx usebounds radius"
            assert nx.diameter(h, usebounds=True, weight=wk) == diameter, "nx usebounds diameter"
            assert set(nx.center(h, usebounds=True, weight=wk)) == {V[i] for i in center}
            assert set(nx.periphery(h, usebounds=True, weight=wk)) == {V[i] for i in periphery}
        c = nx.centroid(h, weight=wk)
        assert set(c) == {V[i] for i in centroid_model(D)}, "nx centroid"
        if not (not g.directed and w is None and nx.is_tree(h)):
            assert c == [V[i] for i in centroid_model(D)], "nx centroid order"
        wi = nx.wiener_index(h, weight=wk)
        assert wi == wiener_model(g, D), f"nx wiener {wi}"
        a = nx.average_shortest_path_length(h, weight=wk)
        assert a == average_model(g, D, w is not None) or (
            isinstance(a, float) and math.isclose(a, average_model(g, D, w is not None), rel_tol=1e-15)), "nx average"
    else:
        assert raises(lambda: nx.diameter(h, weight=wk)) and raises(lambda: nx.radius(h, weight=wk))
        assert raises(lambda: nx.center(h, weight=wk)) and raises(lambda: nx.periphery(h, weight=wk))
        assert raises(lambda: nx.centroid(h, weight=wk))
        assert nx.wiener_index(h, weight=wk) == math.inf
        assert raises(lambda: nx.average_shortest_path_length(h, weight=wk))
    assert nx.density(h) == density_model(g)


def check_path(g, D, w, p):
    vs, es, d = p
    # A walk along the listed edges, simple, of the stated length.
    assert len(set(vs)) == len(vs) and len(es) == len(vs) - 1
    total = 0
    for k, e in enumerate(es):
        a, b = g.ends[e]
        x, y = vs[k], vs[k + 1]
        assert (a, b) == (x, y) or (not g.directed and (b, a) == (x, y))
        total += 1 if w is None else w[e]
    assert total == d == D[vs[0]][vs[-1]]
    ecc = eccentricities_model(D)
    diameter = extrema(ecc)[1]
    assert d == diameter
    # The lexicographically least ordered pair at distance `diameter`.
    pair = min((i, j) for i in range(g.n) for j in range(g.n) if D[i][j] == diameter)
    assert pair == (vs[0], vs[-1]), f"diametral pair {pair} vs {(vs[0], vs[-1])}"
    if g.n <= NX_LIMIT:
        h = to_nx(g, w)
        assert nx.shortest_path_length(h, g.vertices[vs[0]], g.vertices[vs[-1]], weight=None if w is None else "w") == d


# --------------------------------------------------------------------------------------------
# Closed forms for the big cases (n > BIG)
# --------------------------------------------------------------------------------------------


def closed_path(n, name):
    if name == "diameter":
        return f"#{n - 1}"
    if name == "radius":
        return f"#{n // 2}"
    if name == "center":
        return f"[{(n - 1) // 2}]" if n % 2 else f"[{n // 2 - 1}, {n // 2}]"
    if name == "periphery":
        return f"[0, {n - 1}]"
    if name == "wienerIndex":
        return f"#{(n ** 3 - n) // 6}"
    if name == "centroid":
        return closed_path(n, "center")


def closed_star(n, name):  # S(0;1..n-1)
    return {"diameter": "#2", "radius": "#1", "center": "[0]", "periphery": "[" + ", ".join(str(i) for i in range(1, n)) + "]",
            "wienerIndex": f"#{(n - 1) + (n - 1) * (n - 2)}", "centroid": "[0]"}[name]


def closed_cycle(n, name):
    return {"diameter": f"#{n // 2}", "radius": f"#{n // 2}", "center": "all", "periphery": "all",
            "wienerIndex": f"#{n * (n * n // 4) // 2}" if n % 2 == 0 else f"#{n * (n * n - 1) // 8}",
            "eccentricities": f"all {n // 2}"}[name]


def closed(graph_cell, op):
    g = parse_graph(graph_cell)
    _, name, _, _ = parse_op(op)
    src = graph_cell.strip("`")
    m = re.fullmatch(r"U: \[\] P\(0\.\.(\d+)\)", src)
    if m:
        return closed_path(int(m.group(1)) + 1, name)
    m = re.fullmatch(r"U: \[\] S\(0;1\.\.(\d+)\)", src)
    if m:
        return closed_star(int(m.group(1)) + 1, name)
    m = re.fullmatch(r"U: \[\] C\(0\.\.(\d+)\)", src)
    if m:
        return closed_cycle(int(m.group(1)) + 1, name)
    raise AssertionError(f"no closed form for {src} {op}")


def small_closed_checks():
    """The closed forms agree with the model where both run."""
    for n in range(2, 40):
        for name in ("diameter", "radius", "center", "periphery", "wienerIndex", "centroid"):
            cell = f"U: [] P(0..{n - 1})"
            assert evaluate(cell, name, check=False) == closed(cell, name), (n, name)
        for name in ("diameter", "radius", "center", "wienerIndex", "centroid"):
            if n < 3:
                break
            cell = f"U: [] S(0;1..{n - 1})"
            assert evaluate(cell, name, check=False) == closed(cell, name), (n, name)
        if n >= 3:
            cell = f"U: [] C(0..{n - 1})"
            for name in ("diameter", "radius", "wienerIndex"):
                assert evaluate(cell, name, check=False) == closed(cell, name), (n, name)
            assert evaluate(cell, "center", check=False) == fmt_vertices(parse_graph(cell), range(n))
            assert evaluate(cell, "eccentricities", check=False) == fmt_eccs([n // 2] * n)


def random_checks():
    """lcg graphs: bounding, NetworkX usebounds (weighted too) and the model agree."""
    count = 0
    for seed in range(60):
        n = 5 + seed % 23
        cell = f"U: [] P(0..{n - 1}), lcg({n},{seed % 7},{seed})"
        g = parse_graph(cell)
        D = all_distances(g, None)
        cross_check(g, D, None)
        w = [(e * 7 + seed) % 5 + 1 for e in range(g.m)]
        cross_check(g, all_distances(g, w), w)
        dg = parse_graph(f"D: [0..{n - 1}] lcg({n},{2 * n},{seed})")
        cross_check(dg, all_distances(dg, None), None)
        count += 3
    return count


# --------------------------------------------------------------------------------------------
# Catalog
# --------------------------------------------------------------------------------------------


def read_rows(path, prefix):
    lines = path.read_text().splitlines()
    header, rows, order = None, {}, []
    for i, line in enumerate(lines):
        if not line.startswith("|"):
            header = None if not line.strip() else header
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if cells[0] == "ID":
            header = cells
            continue
        if header and re.fullmatch(prefix + r"-\d+", cells[0]):
            r = dict(zip(header, cells))
            r["_line"] = i
            rows[cells[0]] = r
            order.append(cells[0])
    return lines, rows, order


def ta_agreement(r, got):
    m = re.search(r"= (TA-\d+)", r.get("Notes", ""))
    if not m:
        return
    _, ta, _ = read_rows(TA_CASES, "TA")
    t = ta[m.group(1)]
    assert t["Source"].strip("`") == r["Graph"].strip("`"), f"{m.group(1)} source differs"
    top = t["Op"].strip("`")
    assert top.startswith("Tree : ") and top[len("Tree : "):] == r["Op"].strip("`"), f"{m.group(1)} op differs"
    texp = t["Expected"].strip("`")
    assert texp == got, f"{r['ID']}: Tree says {texp}, Distances {got}"


def main():
    fill = "--fill" in sys.argv
    emit = sys.argv[sys.argv.index("--emit") + 1] if "--emit" in sys.argv else None
    lines, rows, order = read_rows(CASES, "DI")
    assert len(order) == len(set(order)), "duplicate IDs"
    bad = 0
    for cid in order:
        if emit and cid != emit:
            continue
        r = rows[cid]
        cell, op, exp = r["Graph"].strip("`"), r["Op"].strip("`"), r["Expected"].strip("`")
        try:
            got = evaluate(cell, op)
        except LookupError:
            got = closed(cell, op)
        else:
            if parse_graph(cell).n > BIG and parse_op(op)[1] != "density":
                assert got == closed(cell, op), f"{cid}: bounding {got} vs closed form"
        if got != "trap" and exp != "?":
            ta_agreement(r, got)
        if emit:
            print(got)
            return
        if exp == "?" and fill:
            cells = lines[r["_line"]].split("|")
            idx = 1 + list(k for k in r if k != "_line").index("Expected")
            cells[idx] = f" `{got}` "
            lines[r["_line"]] = "|".join(cells)
            continue
        if got != exp:
            bad += 1
            print(f"{cid}: expected {exp}, computed {got}")
    if fill:
        CASES.write_text("\n".join(lines) + "\n")
        print("filled")
        return
    small_closed_checks()
    k = random_checks()
    if bad:
        print(f"{bad} disagreements")
        sys.exit(1)
    print(f"{len(order)} cases and {k} random graphs; scipy {'checked' if HAVE_SCIPY else 'SKIPPED'}; all values agree")


if __name__ == "__main__":
    main()
