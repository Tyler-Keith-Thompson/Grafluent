"""Independent reference for the Cliques module (catalog cases.md, CQ-...).

Run:  uv run --quiet --no-project --with networkx==3.7 python3 ref.py
      ... python3 ref.py --fill         rewrite '?' Expected cells of cases.md with computed values
      ... python3 ref.py --emit CQ-101  print the computed value of one case

Every value is computed by the model of api.md, written here in index space the way the Swift
implementation will run it, and then checked independently:

* the simple graph: each row deduplicated in first-appearance order, self-loops dropped
  (api.md "Simple-graph semantics"); every op reads only this;
* core numbers and the degeneracy ordering by Batagelj–Zaversnik exactly as api.md specifies
  (counting sort stable in index order, the bin-swap step in row order), checked against
  peeling by brute force (the k-core is what is left after deleting degree < k repeatedly),
  against NetworkX `core_number` on the simple graph, and the ordering checked to be a
  degeneracy ordering (each vertex has at most `degeneracy` neighbours after it);
* maximal cliques by Eppstein–Löffler–Strash (outer loop in the degeneracy ordering) with
  Tomita pivoting, pivot and branch order as api.md specifies; the *set* checked against
  brute force over all vertex subsets (n <= 14), against NetworkX `find_cliques` and
  `find_cliques_recursive`, and against `enumerate_all_cliques` filtered to maximal ones;
  each clique sorted by index, no clique twice;
* the maximum clique: the lexicographically least largest clique by index, checked by brute
  force over the maximal cliques, its size against NetworkX `max_weight_clique(weight=None)`;
* triangles per vertex by marking (the Swift one-vertex query), the total by Latapy's
  compact-forward listing on the degree order (the Swift whole-graph pass); per-vertex counts
  against NetworkX `triangles` (simple graph and, where it accepts it, the MultiGraph) and the
  total against `len(list(all_triangles))`; clustering, transitivity and average clustering
  against NetworkX `clustering`, `transitivity`, `average_clustering` on the simple graph,
  bit-for-bit for the first two and within 1e-15 relative for the average (Python 3.12's
  `sum` is compensated; the Swift model sums plainly in index order).
"""

import itertools
import math
import re
import sys
from collections import Counter
from pathlib import Path

import networkx as nx

HERE = Path(__file__).resolve().parent
CASES = HERE / "cases.md"
BRUTE_N = 14
NX_LIMIT = 3000


class Trap(Exception):
    pass


# --------------------------------------------------------------------------------------------
# Parsing (the Distances catalog's notation, plus KM and moon)
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


def multipartite(sizes):
    parts, start = [], 0
    for s in sizes:
        parts.append(list(range(start, start + s)))
        start += s
    part = {v: i for i, p in enumerate(parts) for v in p}
    return list(range(start)), [(u, v) for u in range(start) for v in range(u + 1, start) if part[u] != part[v]]


def edge_tokens(s):
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
        elif t.startswith("KM("):
            vs, es = multipartite([int(x) for x in t[3:-1].split(",")])
            extra += vs
            out += es
        elif t.startswith("moon("):
            vs, es = multipartite([3] * int(t[5:-1]))
            extra += vs
            out += es
        elif t.startswith("K("):
            vs = items(t[2:-1])
            if len(vs) == 1:
                vs = list(range(vs[0]))
            extra += vs
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
        elif t.startswith("lcg("):
            n, m, seed = (int(x) for x in t[4:-1].split(","))
            extra += list(range(n))
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
    """A graph as api.md sees it: vertices in order, edges by position, rows in incidentEdges
    order (an undirected self-loop twice), and the simple rows every op reads."""

    def __init__(self, directed, vertices, ends, rev=False):
        self.directed, self.vertices, self.ends = directed, vertices, ends
        self.n, self.m = len(vertices), len(ends)
        rows = [[] for _ in range(self.n)]
        for a, b in ends:
            rows[a].append(b)
            if not directed:
                rows[b].append(a)
        if rev:
            rows = [r[::-1] for r in rows]
        self.rows = rows

    def undirected_view(self):
        assert self.directed
        return G(False, self.vertices, self.ends)

    def simple(self):
        """Each row without self-loops and repeats, in first-appearance order."""
        out = []
        for v, r in enumerate(self.rows):
            seen, row = set(), []
            for w in r:
                if w != v and w not in seen:
                    seen.add(w)
                    row.append(w)
            out.append(row)
        return out


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


# --------------------------------------------------------------------------------------------
# Models (api.md, index space)
# --------------------------------------------------------------------------------------------


def batagelj_zaversnik(adj):
    """(core numbers, ordering) exactly as api.md: stable counting sort by degree in index
    order, then for each vertex in turn, each neighbour in row order with a greater current
    degree swaps to the front of its bin and drops one degree."""
    n = len(adj)
    deg = [len(r) for r in adj]
    md = max(deg, default=0)
    bins = [0] * (md + 1)
    for d in deg:
        bins[d] += 1
    start = 0
    for d in range(md + 1):
        bins[d], start = start, start + bins[d]
    pos, vert = [0] * n, [0] * n
    for v in range(n):
        pos[v] = bins[deg[v]]
        vert[pos[v]] = v
        bins[deg[v]] += 1
    for d in range(md, 0, -1):
        bins[d] = bins[d - 1]
    if md >= 0 and n:
        bins[0] = 0
    for i in range(n):
        v = vert[i]
        for u in adj[v]:
            if deg[u] > deg[v]:
                du, pu = deg[u], pos[u]
                pw = bins[du]
                w = vert[pw]
                if u != w:
                    pos[u], pos[w] = pw, pu
                    vert[pu], vert[pw] = w, u
                bins[du] += 1
                deg[u] -= 1
    return deg, vert


def peel_cores(adj):
    """Brute force: core(v) = the largest k such that v survives deleting degree < k repeatedly."""
    n = len(adj)
    core = [0] * n
    k = 0
    while True:
        alive = set(range(n))
        changed = True
        while changed:
            changed = False
            for v in list(alive):
                if sum(1 for w in adj[v] if w in alive) < k:
                    alive.discard(v)
                    changed = True
        if not alive:
            return core
        for v in alive:
            core[v] = k
        k += 1


def tomita(adj_sets, R, P, X, out):
    if not P and not X:
        out.append(sorted(R))
        return
    best, pivot = -1, None
    for u in sorted(P | X):
        c = len(P & adj_sets[u])
        if c > best:
            best, pivot = c, u
    for w in sorted(P - adj_sets[pivot]):
        tomita(adj_sets, R + [w], P & adj_sets[w], X & adj_sets[w], out)
        P = P - {w}
        X = X | {w}


def maximal_cliques_model(adj):
    """Eppstein–Löffler–Strash: for each v in the degeneracy ordering, Tomita on P = later
    neighbours, X = earlier neighbours (api.md "Order of maximal cliques")."""
    _, order = batagelj_zaversnik(adj)
    rank = {v: i for i, v in enumerate(order)}
    sets = [set(r) for r in adj]
    out = []
    for v in order:
        P = {w for w in sets[v] if rank[w] > rank[v]}
        X = {w for w in sets[v] if rank[w] < rank[v]}
        tomita(sets, [v], P, X, out)
    return out


def brute_maximal(adj):
    n = len(adj)
    sets = [set(r) for r in adj]
    cl = []
    for k in range(1, n + 1):
        for c in itertools.combinations(range(n), k):
            if all(b in sets[a] for a, b in itertools.combinations(c, 2)):
                cl.append(frozenset(c))
    return {c for c in cl if is_maximal(sets, c, n)}


def is_maximal(sets, c, n):
    """No vertex outside `c` is adjacent to all of it."""
    return not any(x not in c and all(x in sets[y] for y in c) for x in range(n))


def triangles_per_vertex(adj):
    """The one-vertex query: mark N(v), count marked neighbours of each neighbour, halve."""
    out = []
    sets = [set(r) for r in adj]
    for v in range(len(adj)):
        t = sum(1 for w in adj[v] for x in adj[w] if x in sets[v])
        assert t % 2 == 0
        out.append(t // 2)
    return out


def triangle_count_of(adj, v):
    mark = set(adj[v])
    t = sum(1 for w in adj[v] for x in adj[w] if x in mark)
    assert t % 2 == 0
    return t // 2


def compact_forward_total(adj):
    """Latapy's compact-forward: orient each edge from lower to higher (degree, index)."""
    n = len(adj)
    key = lambda v: (len(adj[v]), v)
    rank = {v: i for i, v in enumerate(sorted(range(n), key=key))}
    fwd = [sorted((w for w in adj[v] if rank[w] > rank[v]), key=rank.get) for v in range(n)]
    total = 0
    per = [0] * n
    for v in range(n):
        mark = set(fwd[v])
        for w in fwd[v]:
            for x in fwd[w]:
                if x in mark:
                    total += 1
                    per[v] += 1
                    per[w] += 1
                    per[x] += 1
    return total, per


def clustering_model(adj, tri):
    out = []
    for v in range(len(adj)):
        d = len(adj[v])
        out.append(0.0 if d < 2 or tri[v] == 0 else (2 * tri[v]) / (d * (d - 1)))
    return out


def transitivity_model(adj, tri):
    num = sum(tri)  # 3 · triangles
    den = sum(len(r) * (len(r) - 1) // 2 for r in adj)  # connected triples
    return 0.0 if num == 0 else num / den


def average_model(cc):
    if not cc:
        return 0.0
    s = 0.0
    for c in cc:
        s += c
    return s / len(cc)


# --------------------------------------------------------------------------------------------
# Formatting and ops
# --------------------------------------------------------------------------------------------


def fnum(x):
    if isinstance(x, float):
        return repr(x)
    return str(x)


def fv(g, idx):
    return "[" + ", ".join(str(g.vertices[i]) for i in idx) + "]"


def parse_op(op):
    op = op.strip().strip("`")
    view = None
    if op.startswith("undirected > "):
        view, op = "undirected", op[len("undirected > "):]
    m = re.fullmatch(r"(\w+(?:\.\w+)?)(?:\((.*)\))?", op)
    assert m, f"bad op {op!r}"
    return view, m.group(1), m.group(2)


def evaluate(cell, op):
    g = parse_graph(cell)
    view, name, arg = parse_op(op)
    if view == "undirected":
        g = g.undirected_view()
    assert not g.directed, "Cliques ops run on undirected graphs only"
    adj = g.simple()
    n = g.n
    vid = {v: i for i, v in enumerate(g.vertices)}

    def vertex_arg():
        a = arg.split(":", 1)[1].strip()
        if vtok(a) not in vid:
            raise Trap
        return vid[vtok(a)]

    try:
        if name == "maximalCliques":
            return "[" + ", ".join(fv(g, c) for c in maximal_cliques_model(adj)) + "]"
        if name == "maximalCliques.count":
            return "#" + str(len(maximal_cliques_model(adj)))
        if name in ("maximumClique", "cliqueNumber"):
            cs = maximal_cliques_model(adj)
            if not cs:
                best = []
            else:
                w = max(len(c) for c in cs)
                best = min(c for c in cs if len(c) == w)
            return fv(g, best) if name == "maximumClique" else "#" + str(len(best))
        core, order = batagelj_zaversnik(adj)
        if name == "coreNumbers":
            return "[" + ", ".join(map(str, core)) + "]"
        if name == "degeneracy":
            return "#" + str(max(core, default=0))
        if name == "degeneracyOrdering":
            return fv(g, order)
        if name in ("kCore", "kShell"):
            k = int(arg)
            if k < 0:
                raise Trap
            sel = [v for v in range(n) if (core[v] >= k if name == "kCore" else core[v] == k)]
            return fv(g, sel)
        tri = compact_forward_total(adj)[1]
        if name == "triangleCount" and arg is None:
            return "#" + str(sum(tri) // 3)
        if name == "triangleCount":
            return "#" + str(triangle_count_of(adj, vertex_arg()))
        if name == "triangleCounts":
            return "[" + ", ".join(map(str, tri)) + "]"
        cc = clustering_model(adj, tri)
        if name == "clusteringCoefficients":
            return "[" + ", ".join(fnum(c) for c in cc) + "]"
        if name == "clusteringCoefficient":
            return "#" + fnum(cc[vertex_arg()])
        if name == "transitivity":
            return "#" + fnum(transitivity_model(adj, tri))
        if name == "averageClustering":
            return "#" + fnum(average_model(cc))
    except Trap:
        return "trap"
    raise AssertionError(f"unknown op {name}")


# --------------------------------------------------------------------------------------------
# Independent checks
# --------------------------------------------------------------------------------------------


def to_nx_simple(g):
    h = nx.Graph()
    h.add_nodes_from(range(g.n))
    for a, b in g.ends:
        if a != b:
            h.add_edge(a, b)
    return h


def to_nx_multi(g):
    h = nx.MultiGraph()
    h.add_nodes_from(range(g.n))
    h.add_edges_from(g.ends)
    return h


checked_graphs = set()


def cross_check(cell, view):
    key = (cell, view)
    if key in checked_graphs:
        return
    checked_graphs.add(key)
    g = parse_graph(cell)
    if view == "undirected":
        g = g.undirected_view()
    full_check(g)


def full_check(g):
    adj = g.simple()
    n = g.n
    # Simple rows are symmetric.
    sets = [set(r) for r in adj]
    for v in range(n):
        for w in adj[v]:
            assert v in sets[w]
    core, order = batagelj_zaversnik(adj)
    assert sorted(order) == list(range(n))
    degen = max(core, default=0)
    rank = {v: i for i, v in enumerate(order)}
    for v in range(n):
        later = sum(1 for w in adj[v] if rank[w] > rank[v])
        assert later <= core[v] <= degen, "not a degeneracy ordering"
    # Core numbers never decrease along the ordering (BZ removes in nondecreasing core order).
    assert all(core[order[i]] <= core[order[i + 1]] for i in range(n - 1))
    if n <= 400:
        assert core == peel_cores(adj), "BZ vs peeling"
    cl = maximal_cliques_model(adj)
    assert all(c == sorted(c) for c in cl)
    fs = [frozenset(c) for c in cl]
    assert len(set(fs)) == len(fs), "a clique twice"
    for c in cl:
        assert all(b in sets[a] for a, b in itertools.combinations(c, 2))
    if n <= BRUTE_N:
        assert set(fs) == brute_maximal(adj), "maximal cliques vs brute force"
    total, tri = compact_forward_total(adj)
    assert 3 * total == sum(tri)
    if n <= 5000:
        assert triangles_per_vertex(adj) == tri, "compact-forward vs marking"
    cc = clustering_model(adj, tri)
    if n > NX_LIMIT:
        return
    h = to_nx_simple(g)
    if n:
        assert set(fs) == {frozenset(c) for c in nx.find_cliques(h)}, "find_cliques"
        if n <= 400:
            assert set(fs) == {frozenset(c) for c in nx.find_cliques_recursive(h)}
        omega = max(len(c) for c in cl)
        if n <= 400:
            assert nx.max_weight_clique(h, weight=None)[1] == omega
    else:
        assert list(nx.find_cliques(h)) == []
    if n <= 60:
        allc = [frozenset(c) for c in nx.enumerate_all_cliques(h)]
        assert {c for c in allc if is_maximal(sets, c, n)} == set(fs)
    assert [nx.core_number(h)[v] for v in range(n)] == core, "core_number"
    assert [nx.triangles(h)[v] for v in range(n)] == tri, "triangles"
    assert len(list(nx.all_triangles(h))) == total, "all_triangles"
    hm = to_nx_multi(g)
    assert [nx.triangles(hm)[v] for v in range(n)] == tri, "triangles on the MultiGraph"
    assert len(list(nx.all_triangles(hm))) == total
    ncc = nx.clustering(h)
    assert [float(ncc[v]) for v in range(n)] == cc, ("clustering", [ncc[v] for v in range(n)], cc)
    assert float(nx.transitivity(h)) == transitivity_model(adj, tri), "transitivity"
    if n:
        a, b = nx.average_clustering(h), average_model(cc)
        assert abs(a - b) <= 1e-15 * max(1.0, abs(a)), ("average_clustering", a, b)


def random_checks():
    import random

    rnd = random.Random(20261009)
    count = 0
    for trial in range(250):
        n = rnd.randint(0, 13)
        m = rnd.randint(0, n * (n - 1) // 2 + 3) if n else 0
        ends = []
        for _ in range(m):
            a, b = rnd.randrange(n), rnd.randrange(n)
            ends.append((a, b))  # loops and parallels included on purpose
        full_check(G(False, list(range(n)), ends, rev=rnd.random() < 0.3))
        count += 1
    for trial in range(30):
        n = rnd.randint(30, 80)
        p = rnd.choice([0.05, 0.2, 0.4])
        h = nx.gnp_random_graph(n, p, seed=rnd.randrange(1 << 30))
        full_check(G(False, list(range(n)), list(h.edges())))
        count += 1
    return count


def library_quirks():
    """Disagreements quoted in api.md, asserted so they stay true for NetworkX 3.7."""
    # core_number raises on a self-loop; ours ignores the loop.
    h = nx.Graph([(0, 1), (0, 0)])
    try:
        nx.core_number(h)
        raise AssertionError("core_number accepted a self-loop")
    except nx.NetworkXNotImplemented:
        pass
    # triangles(G) accepts a MultiGraph, triangles(G, v) does not.
    hm = nx.MultiGraph([(0, 1), (0, 1), (1, 2), (2, 0)])
    assert nx.triangles(hm) == {0: 1, 1: 1, 2: 1}
    try:
        nx.triangles(hm, 0)
        raise AssertionError("triangles(MultiGraph, v) accepted")
    except nx.NetworkXNotImplemented:
        pass
    for f in (nx.clustering, nx.core_number, nx.transitivity):
        try:
            f(hm)
            raise AssertionError(f"{f.__name__} accepted a MultiGraph")
        except nx.NetworkXNotImplemented:
            pass
    # average_clustering raises on the null graph and with count_zeros=False on a triangle-free graph.
    for f in (lambda: nx.average_clustering(nx.Graph()), lambda: nx.average_clustering(nx.path_graph(3), count_zeros=False)):
        try:
            f()
            raise AssertionError("average_clustering did not raise")
        except ZeroDivisionError:
            pass
    assert nx.transitivity(nx.Graph()) == 0
    # max_weight_clique's tie: two isolated vertices give [1], not [0] (ours: the least).
    e = nx.Graph()
    e.add_nodes_from([0, 1])
    assert nx.max_weight_clique(e, weight=None) == ([1], 1)
    # Directed: core_number uses in + out degree, a reciprocal pair counting twice.
    assert nx.core_number(nx.DiGraph([(0, 1), (1, 0)])) == {0: 2, 1: 2}
    # find_cliques's order is set order: not the index order of each clique.
    assert list(nx.find_cliques(nx.Graph([(0, 1), (1, 2), (2, 0), (2, 3)]))) == [[2, 0, 1], [2, 3]]


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
            assert cells[0] not in rows, f"duplicate {cells[0]}"
            rows[cells[0]] = r
            order.append(cells[0])
    return lines, rows, order


def main():
    fill = "--fill" in sys.argv
    emit = sys.argv[sys.argv.index("--emit") + 1] if "--emit" in sys.argv else None
    lines, rows, order = read_rows(CASES, "CQ")
    bad = 0
    for cid in order:
        if emit and cid != emit:
            continue
        r = rows[cid]
        cell, op, exp = r["Graph"].strip("`"), r["Op"].strip("`"), r["Expected"].strip("`")
        got = evaluate(cell, op)
        if not emit:
            cross_check(cell, parse_op(op)[0])
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
    library_quirks()
    k = random_checks()
    if bad:
        print(f"{bad} disagreements")
        sys.exit(1)
    print(f"{len(order)} cases, {len(checked_graphs)} catalog graphs and {k} random graphs checked; all values agree")


if __name__ == "__main__":
    main()
