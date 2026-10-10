"""Independent reference for the TreeAlgorithms module (catalog cases.md, TA-...).

Run:  uv run --quiet --no-project --with networkx==3.7 python3 ref.py
      ... python3 ref.py --fill        rewrite '?' cells of cases.md with computed values
      ... python3 ref.py --emit TA-101  print the computed value of one case

Every value is computed by the model of api.md written here, in index space the way the Swift
implementation will run (incidence rows in position order, the Trees rooting: parent, parent
edge, depth, preorder, subtree size; preorder RMQ for LCA; heavy-first preorder for HLD; one
rerooting pass for eccentricities), then checked two more ways:

* a naive implementation from the definitions: ancestor sets for LCA, recursion for the Euler
  tour, all-pairs distances by brute force for center / diameter / diameterPath (the
  lexicographically least diametral pair), component sizes after removing each vertex for the
  centroid, a recursive centroid decomposition over vertex sets, and HLD segments expanded back
  into the path they cover;
* NetworkX 3.7: lowest_common_ancestor (on the arborescence), tree_all_pairs_lowest_common_ancestor,
  shortest_path / shortest_path_length, dfs_labeled_edges (Euler tour), dfs_preorder_nodes
  (heavy-first preorder), tree.center, center(weight=), tree.centroid, centroid (the 3.7 name of
  barycenter), diameter(weight=), eccentricity.

Cases with more than BIG vertices skip NetworkX and the naive checks; their values are checked
against closed forms (CLOSED below), derived by hand from the shape of the input.
"""

import math
import re
import sys
from pathlib import Path

import networkx as nx

HERE = Path(__file__).resolve().parent
CASES = HERE / "cases.md"
BIG = 3000


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


def edge_tokens(s, arrow):
    """Edges as (a, b) vertex pairs from `u-v`, `P(...)`, `S(c;a..b)`, `kary(n,k)`."""
    out = []
    for t in split_top(s):
        if t.startswith("P("):
            vs = items(t[2:-1])
            out += list(zip(vs, vs[1:]))
        elif t.startswith("S("):
            c, rest = t[2:-1].split(";")
            out += [(vtok(c), x) for x in items(rest)]
        elif t.startswith("kary("):
            n, k = (int(x) for x in t[5:-1].split(","))
            out += [(i, c) for i in range(n) for c in range(k * i + 1, k * i + k + 1) if c < n]
        else:
            a, b = t.split(arrow)
            out.append((vtok(a), vtok(b)))
    return out


def parse_source(cell):
    """(kind, vertices, ends as vertex-number pairs). Vertices: listed, then endpoints."""
    cell = cell.strip().strip("`")
    kind, rest = cell.split(":", 1)
    kind = kind.strip()
    rest = rest.strip()
    if kind == "parents":
        ps = [None if x.strip() == "_" else int(x) for x in rest.strip("[]").split(",")]
        vs = list(range(len(ps)))
        ends = [(p, i) for i, p in enumerate(ps) if p is not None]
        return "parents", vs, ends
    m = re.match(r"\[(.*?)\]\s*(.*)", rest)
    listed, es = m.group(1), m.group(2)
    vs, seen = [], set()
    for v in items(listed):
        if v not in seen:
            seen.add(v)
            vs.append(v)
    pairs = edge_tokens(es, ">" if kind == "D" else "-")
    for a, b in pairs:
        for x in (a, b):
            if x not in seen:
                seen.add(x)
                vs.append(x)
    num = {v: i for i, v in enumerate(vs)}
    return kind, vs, [(num[a], num[b]) for a, b in pairs]


def parse_weights(s, m):
    s = s.strip()
    if s.startswith("["):
        out = []
        for x in split_top(s[1:-1]):
            out.append(float(x) if x in ("nan",) or "." in x else int(x))
        assert len(out) == m, f"{len(out)} weights for {m} edges"
        return out
    return [int(s)] * m


# --------------------------------------------------------------------------------------------
# The model (api.md, index space)
# --------------------------------------------------------------------------------------------


class Rooted:
    """The Trees layout: rows in position order, rooted by one iterative depth-first walk."""

    def __init__(self, vertices, ends, root):
        n = len(vertices)
        self.vertices, self.n, self.ends, self.root = vertices, n, ends, root
        assert len(ends) == n - 1
        deg = [0] * (n + 1)
        for a, b in ends:
            deg[a + 1] += 1
            deg[b + 1] += 1
        for v in range(n):
            deg[v + 1] += deg[v]
        off, fill = deg, deg[:]
        nbr, edg = [0] * (2 * (n - 1)), [0] * (2 * (n - 1))
        for e, (a, b) in enumerate(ends):
            nbr[fill[a]], edg[fill[a]] = b, e
            fill[a] += 1
            nbr[fill[b]], edg[fill[b]] = a, e
            fill[b] += 1
        self.off, self.nbr, self.edg = off, nbr, edg
        parent, pedge, depth = [-1] * n, [-1] * n, [-1] * n
        size, pos, pre = [1] * n, [0] * n, []
        depth[root] = 0
        pre.append(root)
        stack = [[root, off[root]]]
        while stack:
            top = stack[-1]
            v, k = top
            if k == off[v + 1]:
                stack.pop()
                if parent[v] >= 0:
                    size[parent[v]] += size[v]
                continue
            top[1] = k + 1
            e = edg[k]
            if e == pedge[v]:
                continue
            w = nbr[k]
            assert depth[w] < 0, "not a tree"
            parent[w], pedge[w], depth[w] = v, e, depth[v] + 1
            pos[w] = len(pre)
            pre.append(w)
            stack.append([w, off[w]])
        assert len(pre) == n, "not a tree"
        for i, v in enumerate(pre):
            pos[v] = i
        self.parent, self.pedge, self.depth, self.size, self.pos, self.pre = parent, pedge, depth, size, pos, pre

    def children(self, v):
        return [self.nbr[k] for k in range(self.off[v], self.off[v + 1]) if self.edg[k] != self.pedge[v]]

    def path(self, a, b):
        up, down, ue, de = [a], [b], [], []
        x, y = a, b
        while self.depth[x] > self.depth[y]:
            ue.append(self.pedge[x]); x = self.parent[x]; up.append(x)
        while self.depth[y] > self.depth[x]:
            de.append(self.pedge[y]); y = self.parent[y]; down.append(y)
        while x != y:
            ue.append(self.pedge[x]); x = self.parent[x]; up.append(x)
            de.append(self.pedge[y]); y = self.parent[y]; down.append(y)
        return up + down[:-1][::-1], ue + de[::-1]

    # One-shot LCA: climb by depth.
    def lca_climb(self, a, b):
        while self.depth[a] > self.depth[b]:
            a = self.parent[a]
        while self.depth[b] > self.depth[a]:
            b = self.parent[b]
        while a != b:
            a, b = self.parent[a], self.parent[b]
        return a

    # LowestCommonAncestors: E[i] = pos(parent(pre[i])); LCA = pre[min E(pos a, pos b]].
    def lca_rmq(self, a, b):
        if a == b:
            return a
        if not hasattr(self, "_E"):
            self._E = [0] + [self.pos[self.parent[self.pre[i]]] for i in range(1, self.n)]
        i, j = sorted((self.pos[a], self.pos[b]))
        return self.pre[min(self._E[i + 1: j + 1])]

    def euler(self):
        vs, es = [self.pre[0]], []
        for i in range(1, self.n):
            w = self.pre[i]
            x = vs[-1]
            while x != self.parent[w]:
                es.append(self.pedge[x]); x = self.parent[x]; vs.append(x)
            es.append(self.pedge[w]); vs.append(w)
        x = vs[-1]
        while x != self.root:
            es.append(self.pedge[x]); x = self.parent[x]; vs.append(x)
        return vs, es

    # Heavy-light decomposition.
    def hld(self):
        if hasattr(self, "_hld"):
            return self._hld
        n = self.n
        heavy = [-1] * n
        for v in range(n):
            best = 0
            for c in self.children(v):
                if self.size[c] > best:
                    best, heavy[v] = self.size[c], c
        order, head, hpos = [], [0] * n, [0] * n
        head[self.root] = self.root
        stack = [self.root]
        while stack:
            v = stack.pop()
            hpos[v] = len(order)
            order.append(v)
            cs = self.children(v)
            for c in reversed(cs):
                if c != heavy[v]:
                    head[c] = c
                    stack.append(c)
            if heavy[v] >= 0:
                head[heavy[v]] = head[v]
                stack.append(heavy[v])
        self._hld = (heavy, order, head, hpos)
        return self._hld

    def segments(self, a, b, include=True):
        heavy, order, head, hpos = self.hld()
        d = self.depth
        up, down = [], []
        x, y = a, b
        while head[x] != head[y]:
            if d[head[x]] >= d[head[y]]:
                up.append((hpos[head[x]], hpos[x] + 1, True)); x = self.parent[head[x]]
            else:
                down.append((hpos[head[y]], hpos[y] + 1, False)); y = self.parent[head[y]]
        if d[x] >= d[y]:
            mid = (hpos[y] + (0 if include else 1), hpos[x] + 1, True)
        else:
            mid = (hpos[x] + (0 if include else 1), hpos[y] + 1, False)
        segs = up + [mid] + down[::-1]
        out = []
        for lo, hi, upward in segs:
            if hi > lo:
                out.append((lo, hi, upward and hi - lo >= 2))
        return out

    def hld_lca(self, a, b):
        heavy, order, head, hpos = self.hld()
        while head[a] != head[b]:
            if self.depth[head[a]] >= self.depth[head[b]]:
                a = self.parent[head[a]]
            else:
                b = self.parent[head[b]]
        return a if self.depth[a] <= self.depth[b] else b

    # Eccentricities by one rerooting pass (weights >= 0 checked first, in position order).
    def ecc(self, w):
        for x in w:
            if x != x or x < 0:
                raise Trap("negative or NaN weight")
        n, P, pe = self.n, self.parent, self.pedge
        down = [0] * n
        best1, best2, arg1 = [0] * n, [0] * n, [-1] * n
        for v in reversed(self.pre):
            down[v] = best1[v]
            p = P[v]
            if p >= 0:
                c = w[pe[v]] + down[v]
                if arg1[p] < 0 or c > best1[p]:
                    best2[p], best1[p], arg1[p] = best1[p], c, v
                elif c > best2[p]:
                    best2[p] = c
        up = [0] * n
        for v in self.pre:
            p = P[v]
            if p < 0:
                continue
            other = best2[p] if arg1[p] == v else best1[p]
            up[v] = w[pe[v]] + max(up[p], other)
        return [max(down[v], up[v]) for v in range(n)]

    def distances_from(self, s, w):
        dist = [None] * self.n
        dist[s] = 0
        stack = [s]
        while stack:
            v = stack.pop()
            for k in range(self.off[v], self.off[v + 1]):
                x = self.nbr[k]
                if dist[x] is None:
                    dist[x] = dist[v] + w[self.edg[k]]
                    stack.append(x)
        return dist

    def diameter_path(self, w):
        e = self.ecc(w)
        D = max(e)
        u = min(v for v in range(self.n) if e[v] == D)
        du = self.distances_from(u, w)
        far = max(du)
        v = min(x for x in range(self.n) if du[x] == far)
        vs, es = self.path(u, v)
        return vs, es, far

    def centroid(self):
        n = self.n
        part = [n - self.size[v] for v in range(n)]
        for v in range(n):
            p = self.parent[v]
            if p >= 0:
                part[p] = max(part[p], self.size[v])
        return [v for v in range(n) if 2 * part[v] <= n]

    def centroid_decomposition(self):
        n = self.n
        removed = [False] * n
        out = [-1] * n
        jobs = [(0, -1)]
        par = [-1] * n
        sz = [0] * n
        while jobs:
            s, pc = jobs.pop()
            comp = [s]
            par[s] = -1
            i = 0
            while i < len(comp):
                v = comp[i]; i += 1
                for k in range(self.off[v], self.off[v + 1]):
                    x = self.nbr[k]
                    if not removed[x] and x != par[v]:
                        par[x] = v
                        comp.append(x)
            m = len(comp)
            for v in comp:
                sz[v] = 1
            part = {v: 0 for v in comp}
            for v in reversed(comp):
                if par[v] >= 0:
                    sz[par[v]] += sz[v]
                    part[par[v]] = max(part[par[v]], sz[v])
            c = min(v for v in comp if 2 * max(part[v], m - sz[v]) <= m)
            out[c] = pc
            removed[c] = True
            for k in range(self.off[c], self.off[c + 1]):
                x = self.nbr[k]
                if not removed[x]:
                    jobs.append((x, c))
        return out


# --------------------------------------------------------------------------------------------
# Naive checks and NetworkX
# --------------------------------------------------------------------------------------------


def nx_graph(t, w=None):
    G = nx.Graph()
    G.add_nodes_from(range(t.n))
    for e, (a, b) in enumerate(t.ends):
        G.add_edge(a, b, w=(w[e] if w else 1), pos=e)
    return G


def nx_arb(t):
    D = nx.DiGraph()
    D.add_nodes_from(range(t.n))
    for v in range(t.n):
        if t.parent[v] >= 0:
            D.add_edge(t.parent[v], v)
    return D


def naive_lca(t, a, b):
    anc = set()
    x = a
    while x >= 0:
        anc.add(x); x = t.parent[x]
    while b not in anc:
        b = t.parent[b]
    return b


def naive_euler(t):
    vs, es = [], []

    def go(v):
        vs.append(v)
        for c in t.children(v):
            es.append(t.pedge[c]); go(c)
            es.append(t.pedge[c]); vs.append(v)

    go(t.root)
    return vs, es


def nx_euler(t):
    G = nx_graph(t)
    vs, es = [t.root], []
    for u, v, kind in nx.dfs_labeled_edges(G, source=t.root):
        if u == v or kind == "nontree":
            continue
        es.append(G.edges[u, v]["pos"])
        vs.append(v if kind == "forward" else u)
    return vs, es


def brute_dist(t, w):
    G = nx_graph(t, w)
    return {u: nx.single_source_dijkstra_path_length(G, u, weight="w") for u in range(t.n)}, G


def naive_centroid(t):
    G = nx_graph(t)
    out = []
    for v in range(t.n):
        H = G.copy(); H.remove_node(v)
        biggest = max((len(c) for c in nx.connected_components(H)), default=0)
        if 2 * biggest <= t.n:
            out.append(v)
    return out


def naive_cd(t):
    G = nx_graph(t)
    out = [-1] * t.n

    def go(nodes, pc):
        H = G.subgraph(nodes)
        best = []
        for v in sorted(nodes):
            K = H.copy(); K.remove_node(v)
            big = max((len(c) for c in nx.connected_components(K)), default=0)
            if 2 * big <= len(nodes):
                best.append(v)
        c = best[0]
        out[c] = pc
        K = H.copy(); K.remove_node(c)
        for comp in nx.connected_components(K):
            go(comp, c)

    go(set(range(t.n)), -1)
    return out


# --------------------------------------------------------------------------------------------
# Rendering
# --------------------------------------------------------------------------------------------


def rv(t, v):
    return "nil" if v is None or v < 0 else str(t.vertices[v])


def rlist(t, vs):
    return "[" + ", ".join(rv(t, v) for v in vs) + "]"


def rwalk(t, vs, es):
    return rlist(t, vs) + "/[" + ", ".join(map(str, es)) + "]"


def rparents(t, ps):
    return "[" + ", ".join("_" if p < 0 else str(t.vertices[p]) for p in ps) + "]"


def rsegs(segs):
    return "[" + ", ".join(f"{lo}..<{hi}" + (" R" if r else "") for lo, hi, r in segs) + "]"


def rnum(x):
    if isinstance(x, float) and x.is_integer():
        x = int(x)
    return f"#{x}"


# --------------------------------------------------------------------------------------------
# Evaluating a case
# --------------------------------------------------------------------------------------------

_cache = {}


def build(source, first):
    kind, vs, ends = parse_source(source)
    if first == "Tree":
        assert kind == "U"
        root = 0
    elif first.startswith("RootedTree"):
        m = re.fullmatch(r"RootedTree(?:\(root: (.+)\))?", first)
        if m.group(1) is not None:
            root = vs.index(vtok(m.group(1)))
        else:
            assert kind == "parents"
            root = [i for i in range(len(vs)) if all(b != i for _, b in ends)][0]
    elif first == "Arborescence":
        assert kind in ("D", "parents")
        heads = [b for _, b in ends]
        roots = [i for i in range(len(vs)) if i not in set(heads)]
        assert len(roots) == 1
        root = roots[0]
    else:
        raise ValueError(first)
    key = (source, root)
    if key not in _cache:
        t = Rooted(vs, ends, root)
        if first == "Arborescence":
            assert all(t.parent[b] == a for a, b in ends), "not an arborescence"
        _cache[key] = t
    return _cache[key]


def arg(t, s):
    if not hasattr(t, "num"):
        t.num = {v: i for i, v in enumerate(t.vertices)}
    v = vtok(s)
    if v not in t.num:
        raise Trap("not a vertex")
    return t.num[v]


def call(q):
    m = re.fullmatch(r"([\w.]+)(?:\((.*)\))?(\.\w+)?", q.strip())
    return m.group(1) + (m.group(3) or ""), (split_top(m.group(2)) if m.group(2) is not None else [])


def evaluate(source, op, check=True):
    chain, query = [x.strip() for x in op.split(" : ", 1)]
    steps = [s.strip() for s in chain.split(">")]
    t = build(source, steps[0])
    struct = steps[1] if len(steps) > 1 else steps[0]
    small = t.n <= BIG and check
    name, args = call(query)
    try:
        if name == "lowestCommonAncestor":
            a, b = arg(t, args[0]), arg(t, args[1])
            if struct in ("Tree", "Arborescence") or struct.startswith("RootedTree"):
                r = t.lca_climb(a, b)
            elif struct == "LowestCommonAncestors":
                r = t.lca_rmq(a, b)
                assert r == t.lca_climb(a, b)
            elif struct == "HeavyLightDecomposition":
                r = t.hld_lca(a, b)
            if small:
                assert r == naive_lca(t, a, b)
                assert r == nx.lowest_common_ancestor(nx_arb(t), a, b)
            return rv(t, r)
        if name == "allPairsAgree":
            D = nx_arb(t)
            gold = dict(nx.tree_all_pairs_lowest_common_ancestor(D, root=t.root))
            for a in range(t.n):
                for b in range(t.n):
                    x = t.lca_rmq(a, b)
                    assert x == t.lca_climb(a, b) == t.hld_lca(a, b) == naive_lca(t, a, b)
                    assert x == gold.get((a, b), gold.get((b, a)))
            return "T"
        if name == "distance":
            a, b = arg(t, args[0]), arg(t, args[1])
            l = t.lca_rmq(a, b)
            r = t.depth[a] + t.depth[b] - 2 * t.depth[l]
            if small:
                assert r == nx.shortest_path_length(nx_graph(t), a, b)
            return rnum(r)
        if name in ("eulerTour", "eulerTour.length"):
            vs, es = t.euler()
            assert len(vs) == 2 * t.n - 1 and len(es) == 2 * t.n - 2
            if small:
                assert (vs, es) == naive_euler(t) == nx_euler(t)
            return rwalk(t, vs, es) if name == "eulerTour" else rnum(len(es))
        if struct == "HeavyLightDecomposition":
            heavy, order, head, hpos = t.hld()
            if small:
                # Heavy-first preorder is NetworkX's preorder over rows reordered heavy first.
                G = nx.Graph()
                G.add_nodes_from(range(t.n))
                for v in t.pre:
                    cs = t.children(v)
                    for c in sorted(cs, key=lambda c: c != heavy[v]):
                        G.add_edge(v, c)
                assert list(nx.dfs_preorder_nodes(G, t.root)) == order
                sizes = {v: len(nx.descendants(nx_arb(t), v)) + 1 for v in range(t.n)}
                for v in range(t.n):
                    cs = t.children(v)
                    exp = max(cs, key=lambda c: (sizes[c], -cs.index(c))) if cs else -1
                    assert heavy[v] == exp
            if name == "preorder":
                return rlist(t, order)
            if name == "position":
                return rnum(hpos[arg(t, args[0])])
            if name == "head":
                return rv(t, head[arg(t, args[0])])
            if name == "heavyChild":
                return rv(t, heavy[arg(t, args[0])])
            if name == "subtree":
                v = arg(t, args[0])
                if small:
                    span = sorted(hpos[x] for x in nx.descendants(nx_arb(t), v) | {v})
                    assert span == list(range(hpos[v], hpos[v] + t.size[v]))
                return f"{hpos[v]}..<{hpos[v] + t.size[v]}"
            if name in ("segments", "segments.count"):
                a, b = arg(t, args[0]), arg(t, args[1])
                include = not (len(args) > 2 and args[2].strip() == "includingCommonAncestor: false")
                segs = t.segments(a, b, include)
                # Expanded in walk order, the segments are the path (without the LCA if asked).
                seq = []
                for lo, hi, rev in segs:
                    r = list(range(lo, hi))
                    seq += r[::-1] if rev else r
                    assert len({head[order[p]] for p in r}) == 1, "a segment spans two heavy paths"
                pv = (nx.shortest_path(nx_graph(t), a, b) if small else t.path(a, b)[0])
                l = t.lca_climb(a, b)
                if not include:
                    pv = [x for x in pv if x != l]
                if len(segs) > 0 or pv:
                    # Positions of the path, except the direction of one-position segments.
                    assert [order[p] for p in seq] == pv, (seq, pv)
                assert len(segs) <= 2 * max(1, math.floor(math.log2(t.n))) + 1
                return rsegs(segs) if name == "segments" else rnum(len(segs))
        w = None
        if args and args[0].startswith("weight:"):
            w = parse_weights(args[0].split(":", 1)[1], t.n - 1)
        unit = [1] * (t.n - 1)
        if name == "center":
            e = t.ecc(w or unit)
            lo = min(e)
            r = [v for v in range(t.n) if e[v] == lo]
            if small:
                dist, G = brute_dist(t, w or unit)
                ecc = [max(dist[u].values()) for u in range(t.n)]
                assert ecc == e
                assert r == sorted(nx.center(G, weight="w"))
                if w is None:
                    assert r == sorted(nx.tree.center(G))
            return rlist(t, r)
        if name == "centroid":
            r = t.centroid()
            if small:
                G = nx_graph(t)
                assert r == naive_centroid(t) == sorted(nx.tree.centroid(G)) == sorted(nx.centroid(G))
                # Goldman (1971): on a tree the edge-weighted median is the centroid for any
                # positive weights; NetworkX 3.7 calls the median `centroid`.
                assert r == sorted(nx.centroid(nx_graph(t, [e % 5 + 1 for e in range(t.n - 1)]), weight="w"))
            return rlist(t, r)
        if name in ("centroidDecomposition", "centroidDecomposition.height"):
            ps = t.centroid_decomposition()
            if small:
                assert ps == naive_cd(t)
            depth = [0] * t.n
            for v in range(t.n):
                x, d = v, 0
                while ps[x] >= 0:
                    x, d = ps[x], d + 1
                depth[v] = d
            assert max(depth) <= math.floor(math.log2(t.n))
            return rparents(t, ps) if name == "centroidDecomposition" else rnum(max(depth))
        if name == "diameter":
            e = t.ecc(w or unit)
            r = max(e)
            if small:
                dist, G = brute_dist(t, w or unit)
                assert r == max(max(d.values()) for d in dist.values())
                assert r == nx.diameter(G, weight="w")
            return rnum(r)
        if name == "diameterPath":
            vs, es, D = t.diameter_path(w or unit)
            assert D == max(t.ecc(w or unit))
            assert sum((w or unit)[x] for x in es) == D
            if small:
                dist, G = brute_dist(t, w or unit)
                pairs = [(u, v) for u in range(t.n) for v in range(t.n) if dist[u][v] == D]
                assert (vs[0], vs[-1]) == min(pairs)
                assert vs == nx.shortest_path(G, vs[0], vs[-1])
            return rwalk(t, vs, es) + (f" {rnum(D)}" if w is not None else "")
        raise ValueError(f"unknown query {query}")
    except Trap:
        return "trap"


# --------------------------------------------------------------------------------------------
# Closed forms for the large cases
# --------------------------------------------------------------------------------------------

M = 10**6
CLOSED = {
    "TA-901": f"#{M - 1}",                       # path diameter
    "TA-902": f"[{M // 2 - 1}, {M // 2}]",       # path center: even vertex count, two middles
    "TA-903": f"[{M // 2 - 1}, {M // 2}]",       # path centroid: the same two
    "TA-904": f"{M // 2}",                       # LCA(n-1, n/2) rooted at 0: the shallower
    "TA-905": f"#{M - 4}",                       # distance(3, n-1) along the path
    "TA-906": f"#{2 * (M - 1)}",                 # Euler tour of n vertices has 2n - 2 edges
    "TA-907": f"[0..<{M} R]",                    # rooted at an end, one heavy path, walked up
    "TA-908": f"{M // 2}",                       # LCA of the two ends rooted in the middle
    "TA-909": f"[0..<{M // 2 + 1} R, {M // 2 + 1}..<{M}]",  # up one side, down the other
    "TA-910": "#2",                              # star diameter
    "TA-911": "[0]",                             # star center
    "TA-912": "[0]",                             # star centroid
    "TA-913": "[1, 0, 2]/[0, 1]",                # least diametral pair of a star: leaves 1, 2
    "TA-914": "#1",                              # centroid tree of a star: the center over leaves
    "TA-915": "#16",                             # path of 2^17 - 1 vertices: height 16
    "TA-916": f"#{2 * (M - 1)}",                 # weighted diameter, weight 2 on every edge
    "TA-917": "0",                               # LCA of two leaves in different halves of kary(n, 2)
    "TA-918": "#38",                             # kary(10^6,2): depth-19 leaves under both 1 and 2
}


def check_closed(rows):
    for cid, val in CLOSED.items():
        got = rows[cid]["Expected"].strip().strip("`")
        assert got == val, f"{cid}: closed form {val}, catalog {got}"


# --------------------------------------------------------------------------------------------
# Driver
# --------------------------------------------------------------------------------------------


def read_rows():
    rows, order = {}, []
    lines = CASES.read_text().splitlines()
    header = None
    for i, line in enumerate(lines):
        if not line.startswith("|"):
            header = None if not line.strip() else header
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if cells[0] == "ID":
            header = cells
            continue
        if header is None or set(cells[0]) <= set("-: "):
            continue
        if not cells[0].startswith("TA-"):
            continue
        row = dict(zip(header, cells))
        row["_line"] = i
        rows[cells[0]] = row
        order.append(cells[0])
    return rows, order, lines


def main():
    rows, order, lines = read_rows()
    if "--emit" in sys.argv:
        cid = sys.argv[sys.argv.index("--emit") + 1]
        r = rows[cid]
        print(evaluate(r["Source"].strip("`"), r["Op"].strip("`")))
        return
    fill = "--fill" in sys.argv
    bad = 0
    for cid in order:
        r = rows[cid]
        src, op, exp = r["Source"].strip("`"), r["Op"].strip("`"), r["Expected"].strip("`")
        got = evaluate(src, op)
        if exp == "?" and fill:
            line = lines[r["_line"]]
            cells = line.split("|")
            idx = list(r.keys()).index("Expected") + 1
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
    seen = set()
    for cid in order:
        assert cid not in seen
        seen.add(cid)
    check_closed(rows)
    if bad:
        print(f"{bad} disagreements")
        sys.exit(1)
    print(f"{len(order)} cases; all values agree")


if __name__ == "__main__":
    main()
