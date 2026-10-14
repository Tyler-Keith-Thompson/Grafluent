#!/usr/bin/env python3
"""Reference model for GraphDrawing (Tests/Catalogs/GraphDrawing).

Run: uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with numpy==2.3.4 \
         --with scipy==1.18.1 python3 Tests/Catalogs/GraphDrawing/ref.py [--write] [--stress] [--bench]

Coordinates only: every function here returns points in the plane, one per vertex (and, for a
layered drawing, bend points per edge). The model works in index space, from the definitions in
api.md:

  * Drawing: rescaled(scale:center:) is NetworkX's rescale_layout (subtract the mean, divide by
    the largest absolute coordinate, multiply by scale), then a translation; boundingBox is the
    componentwise min and max.
  * circularLayout: vertex i of n at center + radius (cos 2*pi*i/n, sin 2*pi*i/n); one vertex at
    the center.
  * reingoldTilfordLayout: Walker's algorithm in Buchheim, Juenger and Leipert's linear form,
    separation 1, y = depth, root at x = 0. reingoldTilfordCircularLayout: igraph's polar map.
  * sugiyamaLayout: Eades-Lin-Smyth cycle removal, minimum-span layering (network simplex's
    problem, solved here as a linear program), one dummy per layer an edge crosses, barycenter crossing reduction with the tie rules of api.md, Brandes-Koepf
    alignment with longest-path compaction, balanced by the average median.
  * fruchtermanReingoldLayout and stressMajorizationLayout are not pinned point by point; the model
    runs them to check that the quality thresholds the rows pin are reachable, and NetworkX gives
    the baselines the thresholds come from.

Cross-checks: NetworkX 3.7 (circular_layout, rescale_layout, spring_layout, kamada_kawai_layout,
spectral_layout, bfs_layout, multipartite_layout, forceatlas2_layout) and python-igraph 1.0.0
(layout_reingold_tilford, layout_reingold_tilford_circular, layout_sugiyama). --write regenerates
cases.md; without it the run fails if cases.md differs. --stress adds random trees, DAGs and graphs.
--bench prints baseline timings.
"""
import math
import os
import statistics
import sys
import time
import warnings
from collections import defaultdict, deque

warnings.simplefilter("ignore")

import igraph as ig  # noqa: E402
import networkx as nx  # noqa: E402
import numpy as np  # noqa: E402

sys.setrecursionlimit(100000)
HERE = os.path.dirname(os.path.abspath(__file__))
MASK = (1 << 64) - 1
TAU = 2 * math.pi


# ============================================================================ random streams

def rotl(x, k):
    return ((x << k) | (x >> (64 - k))) & MASK


class SplitMix64:
    def __init__(self, seed):
        self.state = seed & MASK

    def next(self):
        self.state = (self.state + 0x9E3779B97F4A7C15) & MASK
        z = self.state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)


class Xoshiro256StarStar:
    """RandomGraphs' generator: xoshiro256** seeded through SplitMix64 (see that catalog)."""

    def __init__(self, seed):
        sm = SplitMix64(seed)
        self.s = [sm.next() for _ in range(4)]
        self.draws = 0

    def next(self):
        s = self.s
        result = (rotl((s[1] * 5) & MASK, 7) * 9) & MASK
        t = (s[1] << 17) & MASK
        s[2] ^= s[0]
        s[3] ^= s[1]
        s[1] ^= s[2]
        s[0] ^= s[3]
        s[2] ^= t
        s[3] = rotl(s[3], 45)
        self.draws += 1
        return result

    def uniform01(self):
        return (self.next() >> 11) * (2.0 ** -53)


def lcg_stream(seed):
    """The 64-bit LCG the row notation uses for large inputs (Knuth's MMIX constants)."""
    x = seed & MASK
    while True:
        x = (x * 6364136223846793005 + 1442695040888963407) & MASK
        yield x >> 33


# ============================================================================ graphs

class G:
    def __init__(self, directed, n, edges):
        self.directed = directed
        self.n = n
        self.edges = list(edges)

    def nx(self):
        g = nx.MultiDiGraph() if self.directed else nx.MultiGraph()
        g.add_nodes_from(range(self.n))
        g.add_edges_from(self.edges)
        return g

    def simple_nx(self):
        g = nx.DiGraph() if self.directed else nx.Graph()
        g.add_nodes_from(range(self.n))
        g.add_edges_from((u, v) for u, v in self.edges if u != v)
        return g

    def ig(self):
        return ig.Graph(n=self.n, edges=self.edges, directed=self.directed)

    def neighbors(self):
        adj = [[] for _ in range(self.n)]
        for u, v in self.edges:
            if u != v:
                adj[u].append(v)
                adj[v].append(u)
        return adj


def parse(spec):
    """`U:` / `D:` then `n=N;` then comma-separated items (see the notation in cases.md)."""
    kind, rest = spec.split(":", 1)
    directed = kind.strip() == "D"
    rest = rest.strip()
    n = 0
    edges = []
    if rest.startswith("n="):
        head, _, rest = rest.partition(";")
        n = int(head[2:])
    items = split_items(rest)
    sep = ">" if directed else "-"
    for it in items:
        it = it.strip()
        if not it:
            continue
        if it.startswith("P(") or it.startswith("C("):
            vs = [int(x) for x in it[2:-1].split(",")]
            for a, b in zip(vs, vs[1:]):
                edges.append((a, b))
            if it[0] == "C":
                edges.append((vs[-1], vs[0]))
        elif it.startswith("K("):
            k = int(it[2:-1])
            n = max(n, k)
            edges += [(i, j) for i in range(k) for j in range(i + 1, k)]
        elif it.startswith("grid("):
            r, c = (int(x) for x in it[5:-1].split(","))
            n = max(n, r * c)
            for i in range(r):
                for j in range(c):
                    v = i * c + j
                    if j + 1 < c:
                        edges.append((v, v + 1))
                    if i + 1 < r:
                        edges.append((v, v + c))
        elif it.startswith("Q("):
            d = int(it[2:-1])
            n = max(n, 1 << d)
            for i in range(1 << d):
                for k in range(d):
                    j = i ^ (1 << k)
                    if i < j:
                        edges.append((i, j))
        elif it.startswith("petersen"):
            n = max(n, 10)
            edges += [(i, (i + 1) % 5) for i in range(5)]
            edges += [(i, i + 5) for i in range(5)]
            edges += [(5 + i, 5 + (i + 2) % 5) for i in range(5)]
        elif it.startswith("lcggraph("):
            vn, m, s = (int(x) for x in it[9:-1].split(","))
            n = max(n, vn)
            st = lcg_stream(s)
            while m:
                a, b = next(st) % vn, next(st) % vn
                if a != b:
                    edges.append((a, b))
                    m -= 1
        elif it.startswith("lcgdag("):
            vn, m, s = (int(x) for x in it[7:-1].split(","))
            n = max(n, vn)
            st = lcg_stream(s)
            while m:
                a, b = next(st) % vn, next(st) % vn
                if a != b:
                    edges.append((min(a, b), max(a, b)))
                    m -= 1
        elif "=" in it and not directed:
            a, b = (int(x) for x in it.split("="))
            edges += [(a, b), (a, b)]
        else:
            a, b = (int(x) for x in it.split(sep))
            edges.append((a, b))
    for u, v in edges:
        n = max(n, u + 1, v + 1)
    return G(directed, n, edges)


def split_items(s):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur)
    return out


def parse_tree(spec):
    """`T: parents [p0, p1, …]` (None is the root), `T: bal(b,h)`, `T: lcgtree(n,s)`."""
    s = spec.split(":", 1)[1].strip()
    if s.startswith("bal("):
        b, h = (int(x) for x in s[4:-1].split(","))
        g = nx.balanced_tree(b, h)
        n = g.number_of_nodes()
        par = [None] * n
        for v in range(1, n):
            par[v] = (v - 1) // b
        return par
    if s.startswith("lcgtree("):
        n, seed = (int(x) for x in s[8:-1].split(","))
        st = lcg_stream(seed)
        return [None] + [next(st) % i for i in range(1, n)]
    body = s[1:-1].strip()
    return [None if x.strip() == "nil" else int(x) for x in body.split(",")] if body else []


def tree_children(par):
    n = len(par)
    ch = [[] for _ in range(n)]
    root = None
    for v in range(n):
        if par[v] is None:
            root = v
        else:
            ch[par[v]].append(v)
    return root, ch


# ============================================================================ Drawing

def rescaled(pos, scale=1.0, center=(0.0, 0.0)):
    """NetworkX rescale_layout, then + center. Empty stays empty."""
    if not pos:
        return []
    n = len(pos)
    mx = sum(p[0] for p in pos) / n
    my = sum(p[1] for p in pos) / n
    q = [(x - mx, y - my) for x, y in pos]
    lim = max(max(abs(x), abs(y)) for x, y in q)
    if lim > 0:
        q = [(x * scale / lim, y * scale / lim) for x, y in q]
    return [(x + center[0], y + center[1]) for x, y in q]


def bounding_box(pos):
    if not pos:
        return None
    return ((min(p[0] for p in pos), min(p[1] for p in pos)),
            (max(p[0] for p in pos), max(p[1] for p in pos)))


# ============================================================================ circular

def circular(n, radius=1.0, center=(0.0, 0.0)):
    if n == 1:
        return [center]
    return [(center[0] + radius * math.cos(TAU * i / n), center[1] + radius * math.sin(TAU * i / n))
            for i in range(n)]


# ============================================================================ Reingold-Tilford

def reingold_tilford(par):
    """Buchheim-Juenger-Leipert's linear Walker; separation 1; y = depth; root at x = 0."""
    n = len(par)
    if n == 0:
        return []
    root, ch = tree_children(par)
    number = [0] * n
    for v in range(n):
        for i, c in enumerate(ch[v]):
            number[c] = i
    prelim = [0.0] * n
    mod = [0.0] * n
    shift = [0.0] * n
    change = [0.0] * n
    thread = [None] * n
    ancestor = list(range(n))

    def left_sibling(v):
        p = par[v]
        return None if p is None or number[v] == 0 else ch[p][number[v] - 1]

    def next_left(v):
        return ch[v][0] if ch[v] else thread[v]

    def next_right(v):
        return ch[v][-1] if ch[v] else thread[v]

    def move_subtree(wl, wr, s):
        k = number[wr] - number[wl]
        change[wr] -= s / k
        shift[wr] += s
        change[wl] += s / k
        prelim[wr] += s
        mod[wr] += s

    def apportion(v, default):
        w = left_sibling(v)
        if w is None:
            return default
        vip = vop = v
        vim = w
        vom = ch[par[v]][0]
        sip, sop, sim, som = mod[vip], mod[vop], mod[vim], mod[vom]
        while next_right(vim) is not None and next_left(vip) is not None:
            vim = next_right(vim)
            vip = next_left(vip)
            vom = next_left(vom)
            vop = next_right(vop)
            ancestor[vop] = v
            s = (prelim[vim] + sim) - (prelim[vip] + sip) + 1.0
            if s > 0:
                a = ancestor[vim] if par[ancestor[vim]] == par[v] else default
                move_subtree(a, v, s)
                sip += s
                sop += s
            sim += mod[vim]
            sip += mod[vip]
            som += mod[vom]
            sop += mod[vop]
        if next_right(vim) is not None and next_right(vop) is None:
            thread[vop] = next_right(vim)
            mod[vop] += sim - sop
        if next_left(vip) is not None and next_left(vom) is None:
            thread[vom] = next_left(vip)
            mod[vom] += sip - som
            default = v
        return default

    def execute_shifts(v):
        s = c = 0.0
        for w in reversed(ch[v]):
            prelim[w] += s
            mod[w] += s
            c += change[w]
            s += shift[w] + c

    def first_walk(v):
        w = left_sibling(v)
        if not ch[v]:
            prelim[v] = prelim[w] + 1.0 if w is not None else 0.0
            return
        default = ch[v][0]
        for c in ch[v]:
            first_walk(c)
            default = apportion(c, default)
        execute_shifts(v)
        mid = (prelim[ch[v][0]] + prelim[ch[v][-1]]) / 2
        if w is not None:
            prelim[v] = prelim[w] + 1.0
            mod[v] = prelim[v] - mid
        else:
            prelim[v] = mid

    first_walk(root)
    pos = [None] * n
    stack = [(root, -prelim[root], 0)]
    while stack:
        v, m, d = stack.pop()
        pos[v] = (prelim[v] + m, float(d))
        for c in ch[v]:
            stack.append((c, m + mod[v], d + 1))
    return pos


def rt_circular(par):
    """igraph's polar map: angle = (x - min x) * 2*pi*(n - 1)/n / (max x - min x) (no division
    when the width is 0), radius = depth."""
    pos = reingold_tilford(par)
    if not pos:
        return []
    n = len(pos)
    xs = [p[0] for p in pos]
    lo, hi = min(xs), max(xs)
    ratio = TAU * (n - 1.0) / n
    if hi > lo:
        ratio /= hi - lo
    out = []
    for x, d in pos:
        a = (x - lo) * ratio
        out.append((d * math.cos(a), d * math.sin(a)))
    return out


def mirrored(par):
    """The same tree with every child list reversed, renumbered in preorder so that
    RootedTree(parents:) lists children by ascending vertex. Returns (parents, old -> new)."""
    root, ch = tree_children(par)
    n = len(par)
    order = []
    stack = [root]
    while stack:
        v = stack.pop()
        order.append(v)
        stack.extend(ch[v])  # reversed children: push in order, pop last first
    new = {v: i for i, v in enumerate(order)}
    par2 = [None] * n
    for v in range(n):
        if par[v] is not None:
            par2[new[v]] = new[par[v]]
    return par2, new


def tree_invariants(par, pos):
    """Separation >= 1 at each depth in left-to-right order, a parent centred over its first and
    last child, y = depth. Returns a list of violations."""
    bad = []
    root, ch = tree_children(par)
    bydepth = defaultdict(list)
    for v, (x, y) in enumerate(pos):
        bydepth[y].append(x)
    for y, xs in bydepth.items():
        xs.sort()
        for a, b in zip(xs, xs[1:]):
            if b - a < 1 - 1e-9:
                bad.append(f"overlap at depth {y}")
    for v in range(len(par)):
        if ch[v]:
            mid = (pos[ch[v][0]][0] + pos[ch[v][-1]][0]) / 2
            if abs(mid - pos[v][0]) > 1e-9:
                bad.append(f"vertex {v} not centred")
            xs = [pos[c][0] for c in ch[v]]
            if xs != sorted(xs):
                bad.append(f"children of {v} out of order")
    return bad


# ============================================================================ Sugiyama

def eades_lin_smyth(n, arcs):
    """The vertex sequence of Eades, Lin and Smyth's greedy heuristic. Tie rules (api.md): sinks
    and sources leave in FIFO order of becoming sinks/sources, seeded in index order; otherwise
    the remaining vertex with the largest out-degree minus in-degree, least index on ties.
    Self-loops are ignored; parallel arcs count."""
    outd = [0] * n
    ind = [0] * n
    succ = [[] for _ in range(n)]
    pred = [[] for _ in range(n)]
    for u, v in arcs:
        if u == v:
            continue
        outd[u] += 1
        ind[v] += 1
        succ[u].append(v)
        pred[v].append(u)
    alive = [True] * n
    left, right = [], []
    remaining = n
    sinks = deque(v for v in range(n) if outd[v] == 0)
    sources = deque(v for v in range(n) if outd[v] != 0 and ind[v] == 0)

    def remove(v):
        nonlocal remaining
        alive[v] = False
        remaining -= 1
        for w in pred[v]:
            if alive[w]:
                outd[w] -= 1
                if outd[w] == 0:
                    sinks.append(w)
        for w in succ[v]:
            if alive[w]:
                ind[w] -= 1
                if ind[w] == 0 and outd[w] != 0:
                    sources.append(w)

    while remaining:
        if sinks:
            v = sinks.popleft()
            if alive[v]:
                right.append(v)
                remove(v)
            continue
        if sources:
            v = sources.popleft()
            if alive[v]:
                left.append(v)
                remove(v)
            continue
        best = max((v for v in range(n) if alive[v]), key=lambda v: (outd[v] - ind[v], -v))
        left.append(best)
        remove(best)
    return left + list(reversed(right))


def sugiyama(n, arcs, layers=None, max_iterations=100):
    """Returns dict: layer (per vertex), reversed (edge positions), order (per layer, nodes as
    ('v', i) or ('d', edge, k)), x per node, crossings, positions, bends per edge."""
    m = len(arcs)
    reversed_edges = []
    if layers is None:
        seq = eades_lin_smyth(n, arcs)
        rank = [0] * n
        for i, v in enumerate(seq):
            rank[v] = i
        dag = []
        for e, (u, v) in enumerate(arcs):
            if u == v:
                dag.append(None)
            elif rank[u] < rank[v]:
                dag.append((u, v))
            else:
                dag.append((v, u))
                reversed_edges.append(e)
        span, layer = min_span_layering(n, dag)
        if layer is None:
            return {"layer": None, "span": span, "reversed": reversed_edges}
    else:
        layer = list(layers)
        dag = []
        for e, (u, v) in enumerate(arcs):
            if u == v or layer[u] == layer[v]:
                dag.append(None)
            elif layer[u] < layer[v]:
                dag.append((u, v))
            else:
                dag.append((v, u))
                reversed_edges.append(e)
    L = (max(layer) + 1) if n else 0
    # nodes and chains
    order = [[] for _ in range(L)]
    for v in range(n):
        order[layer[v]].append(("v", v))
    chains = [None] * m
    for e, a in enumerate(dag):
        if a is None:
            continue
        u, v = a
        chain = [("v", u)]
        for k, l in enumerate(range(layer[u] + 1, layer[v])):
            d = ("d", e, k)
            order[l].append(d)
            chain.append(d)
        chain.append(("v", v))
        chains[e] = chain
    # segments between consecutive layers
    down = defaultdict(list)  # node -> neighbours in the layer below
    up = defaultdict(list)
    lay = {}
    for l in range(L):
        for x in order[l]:
            lay[x] = l
    segs = []
    for chain in chains:
        if chain is None:
            continue
        for a, b in zip(chain, chain[1:]):
            down[a].append(b)
            up[b].append(a)
            segs.append((a, b))

    def crossings(ordr):
        pos = {}
        for l in range(L):
            for i, x in enumerate(ordr[l]):
                pos[x] = i
        total = 0
        bylayer = defaultdict(list)
        for a, b in segs:
            bylayer[lay[a]].append((pos[a], pos[b]))
        for l, ss in bylayer.items():
            for i in range(len(ss)):
                for j in range(i + 1, len(ss)):
                    (a1, b1), (a2, b2) = ss[i], ss[j]
                    if (a1 - a2) * (b1 - b2) < 0:
                        total += 1
        return total

    def sweep(ordr):
        changed = False
        for direction in ("down", "up"):
            rng = range(1, L) if direction == "down" else range(L - 2, -1, -1)
            for l in rng:
                fixed = ordr[l - 1] if direction == "down" else ordr[l + 1]
                fpos = {x: i for i, x in enumerate(fixed)}
                nb = up if direction == "down" else down
                keys = []
                for i, x in enumerate(ordr[l]):
                    ns = nb[x]
                    keys.append((sum(fpos[y] for y in ns) / len(ns)) if ns else float(i))
                new = [x for _, _, x in sorted(zip(keys, range(len(keys)), ordr[l]))]
                if new != ordr[l]:
                    changed = True
                    ordr[l] = new
        return changed

    best = [list(o) for o in order]
    best_c = crossings(best)
    cur = [list(o) for o in order]
    iterations = 0
    for _ in range(max_iterations):
        if best_c == 0:
            break
        iterations += 1
        changed = sweep(cur)
        c = crossings(cur)
        if c < best_c:
            best_c = c
            best = [list(o) for o in cur]
        if not changed:
            break
    x = brandes_koepf(best, up, down, L)
    pos = [(x[("v", v)], float(layer[v])) for v in range(n)]
    bends = []
    for e in range(m):
        chain = chains[e]
        if chain is None:
            bends.append([])
            continue
        pts = [(x[d], float(lay[d])) for d in chain[1:-1]]
        if e in reversed_edges:
            pts.reverse()
        bends.append(pts)
    return {"layer": layer, "reversed": reversed_edges, "order": best, "crossings": best_c,
            "pos": pos, "bends": bends, "x": x, "layers": L}


def components(n, pairs):
    parent = list(range(n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    for u, v in pairs:
        parent[find(u)] = find(v)
    groups = defaultdict(list)
    for v in range(n):
        groups[find(v)].append(v)
    return sorted(groups.values())


def min_span_layering(n, dag):
    """Network simplex's problem (Gansner et al. 1993): integer layers with layer(v) >= layer(u) + 1
    for every arc u -> v, minimizing the total span sum(layer(v) - layer(u)) over arcs (parallel
    arcs count each), each connected component shifted so its least layer is 0. Solved as an LP
    (the constraint matrix is totally unimodular). Returns (span, layers) when the optimal
    layering is unique up to those shifts, else (span, None)."""
    from scipy.optimize import linprog
    arcs = [a for a in dag if a]
    if not arcs:
        return 0, [0] * n
    c = np.zeros(n)
    A = np.zeros((len(arcs), n))
    for i, (u, v) in enumerate(arcs):
        c[v] += 1
        c[u] -= 1
        A[i, u] = 1
        A[i, v] = -1
    b = -np.ones(len(arcs))
    bounds = [(0, n)] * n
    res = linprog(c, A_ub=A, b_ub=b, bounds=bounds, method="highs")
    opt = round(res.fun)
    A2 = np.vstack([A, c])
    b2 = np.append(b, opt + 1e-9)
    layer = [0] * n
    for comp in components(n, arcs):
        r = comp[0]
        diffs = {}
        for v in comp[1:]:
            obj = np.zeros(n)
            obj[v] = 1
            obj[r] = -1
            lo = linprog(obj, A_ub=A2, b_ub=b2, bounds=bounds, method="highs").fun
            hi = -linprog(-obj, A_ub=A2, b_ub=b2, bounds=bounds, method="highs").fun
            if abs(hi - lo) > 1e-6:
                return opt, None
            diffs[v] = round(lo)
        diffs[r] = 0
        m = min(diffs.values())
        for v in comp:
            layer[v] = diffs[v] - m
    return opt, layer


def brandes_koepf(order, up, down, L):
    """Brandes-Koepf: type-1 conflicts, four vertical alignments, longest-path compaction over
    the block graph with separation 1, aligned to the narrowest, average median."""
    if L == 0:
        return {}
    is_dummy = lambda x: x[0] == "d"  # noqa: E731
    pos = {}
    for l in range(L):
        for i, x in enumerate(order[l]):
            pos[x] = i
    # type-1 conflicts: a non-inner segment crossing an inner segment (both ends dummies)
    marked = set()
    for l in range(1, L):
        upper, lower = order[l - 1], order[l]
        k0 = 0
        start = 0
        for l1, v in enumerate(lower):
            inner = [u for u in up[v] if is_dummy(u) and is_dummy(v)]
            if l1 == len(lower) - 1 or inner:
                k1 = len(upper) - 1
                if inner:
                    k1 = pos[inner[0]]
                for w in lower[start:l1 + 1]:
                    for u in up[w]:
                        k = pos[u]
                        if (k < k0 or k > k1) and not (is_dummy(u) and is_dummy(w)):
                            marked.add((u, w))
                start = l1 + 1
                k0 = k1
    results = []
    for vdir in ("up", "down"):
        for hdir in ("left", "right"):
            layers = list(range(L)) if vdir == "up" else list(range(L - 1, -1, -1))
            ordr = [order[l] if hdir == "left" else list(reversed(order[l])) for l in range(L)]
            p = {}
            for l in range(L):
                for i, x in enumerate(ordr[l]):
                    p[x] = i
            nbrs = up if vdir == "up" else down
            root = {x: x for l in range(L) for x in ordr[l]}
            align = dict(root)
            for idx in range(1, L):
                l = layers[idx]
                r = -1
                for v in ordr[l]:
                    ns = sorted(nbrs[v], key=lambda u: p[u])
                    if not ns:
                        continue
                    d = len(ns)
                    meds = sorted({(d - 1) // 2, d // 2})
                    for mi in meds:
                        if align[v] != v:
                            break
                        u = ns[mi]
                        seg = (u, v) if vdir == "up" else (v, u)
                        if seg not in marked and r < p[u]:
                            align[u] = v
                            root[v] = root[u]
                            align[v] = root[v]
                            r = p[u]
            # block graph: block(a) -> block(b) when a is immediately left of b in a layer
            blocks = sorted({root[x] for x in root}, key=lambda b: (layers.index(lay_of(order, b)), p[b]))
            succ = defaultdict(set)
            indeg = defaultdict(int)
            for l in range(L):
                row = ordr[l]
                for a, b in zip(row, row[1:]):
                    ra, rb = root[a], root[b]
                    if rb not in succ[ra]:
                        succ[ra].add(rb)
                        indeg[rb] += 1
            xb = {b: 0.0 for b in blocks}
            q = deque(b for b in blocks if indeg[b] == 0)
            while q:
                b = q.popleft()
                for c in sorted(succ[b], key=lambda c: blocks.index(c)):
                    xb[c] = max(xb[c], xb[b] + 1.0)
                    indeg[c] -= 1
                    if indeg[c] == 0:
                        q.append(c)
            xs = {x: (xb[root[x]] if hdir == "left" else -xb[root[x]]) for x in root}
            results.append(xs)
    widths = [max(r.values()) - min(r.values()) for r in results]
    k = min(range(4), key=lambda i: (widths[i], i))
    ref = results[k]
    lo, hi = min(ref.values()), max(ref.values())
    shifted = []
    for i, r in enumerate(results):
        if i % 2 == 0:  # left alignments: match the narrowest's minimum
            s = lo - min(r.values())
        else:
            s = hi - max(r.values())
        shifted.append({x: v + s for x, v in r.items()})
    final = {}
    for x in ref:
        vals = sorted(r[x] for r in shifted)
        final[x] = (vals[1] + vals[2]) / 2
    m = min(final.values())
    return {x: v - m for x, v in final.items()}


def lay_of(order, x):
    for l, row in enumerate(order):
        if x in row:
            return l
    raise KeyError(x)


def sugiyama_invariants(n, arcs, res):
    bad = []
    layer = res["layer"]
    rev = set(res["reversed"])
    for e, (u, v) in enumerate(arcs):
        if u == v:
            continue
        a, b = (v, u) if e in rev else (u, v)
        if layer[a] >= layer[b]:
            bad.append(f"edge {e} not downward")
        if len(res["bends"][e]) != layer[b] - layer[a] - 1:
            bad.append(f"edge {e} bend count")
    for row in res["order"]:
        xs = [res["x"][x] for x in row]
        for a, b in zip(xs, xs[1:]):
            if b - a < 1 - 1e-9:
                bad.append("separation")
    return bad


# ============================================================================ metrics

def hop_distances(g):
    adj = g.neighbors()
    n = g.n
    D = np.full((n, n), np.inf)
    for s in range(n):
        D[s, s] = 0
        q = deque([s])
        while q:
            v = q.popleft()
            for w in adj[v]:
                if D[s, w] == np.inf:
                    D[s, w] = D[s, v] + 1
                    q.append(w)
    return D


def target_distances(g, length=1.0):
    """Hop distances times a uniform edge length; pairs in different components get
    1 + length * sqrt(n), the mean edge length times sqrt(n) plus one (api.md)."""
    D = hop_distances(g) * length
    D[np.isinf(D)] = 1 + length * math.sqrt(g.n)
    return D


def normalized_stress(g, pos, D=None):
    """Scale-free stress with weights d^-2 over connected pairs:
    min_s sum w (s|xi-xj| - d)^2 / sum w d^2 = 1 - (sum w d e)^2 / (sum w d^2 * sum w e^2)."""
    if D is None:
        D = hop_distances(g)
    P = np.asarray(pos, float)
    iu = np.triu_indices(g.n, 1)
    d = D[iu]
    ok = np.isfinite(d)
    d = d[ok]
    e = np.linalg.norm(P[iu[0]] - P[iu[1]], axis=1)[ok]
    w = d ** -2.0
    a, b, c = (w * d * e).sum(), (w * d * d).sum(), (w * e * e).sum()
    if b == 0 or c == 0:
        return 1.0
    return float(1 - a * a / (b * c))


def raw_stress(D, P):
    n = len(P)
    iu = np.triu_indices(n, 1)
    d = D[iu]
    e = np.linalg.norm(P[iu[0]] - P[iu[1]], axis=1)
    return float(((e - d) ** 2 / d ** 2).sum())


def segment_crossings(g, pos):
    """Pairs of non-loop edges with no common endpoint whose segments cross properly."""
    P = [tuple(p) for p in pos]
    es = [(u, v) for u, v in g.edges if u != v]

    def orient(a, b, c):
        v = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
        return 0 if abs(v) < 1e-12 else (1 if v > 0 else -1)

    total = 0
    for i in range(len(es)):
        a, b = es[i]
        for j in range(i + 1, len(es)):
            c, d = es[j]
            if len({a, b, c, d}) < 4:
                continue
            p1, p2, p3, p4 = P[a], P[b], P[c], P[d]
            if orient(p1, p2, p3) * orient(p1, p2, p4) < 0 and orient(p3, p4, p1) * orient(p3, p4, p2) < 0:
                total += 1
    return total


# ============================================================================ force-directed and stress

def initial_random(n, seed):
    rng = Xoshiro256StarStar(seed)
    pts = [(rng.uniform01(), rng.uniform01()) for _ in range(n)]
    return pts, rng.draws


def fruchterman_reingold(g, pos0, iterations=50, k=None, threshold=1e-4):
    n = g.n
    P = np.array(pos0, float).reshape(n, 2)
    if n <= 1:
        return P
    if k is None:
        k = math.sqrt(1.0 / n)
    A = np.zeros((n, n))
    for u, v in g.edges:
        if u != v:
            A[u, v] += 1
            A[v, u] += 1
    t = 0.1 * max(np.ptp(P[:, 0]), np.ptp(P[:, 1]))
    dt = t / (iterations + 1)
    for _ in range(iterations):
        delta = P[:, None, :] - P[None, :, :]
        dist = np.linalg.norm(delta, axis=-1)
        np.clip(dist, 0.01, None, out=dist)
        disp = np.einsum("ijk,ij->ik", delta, k * k / dist ** 2 - A * dist / k)
        length = np.linalg.norm(disp, axis=-1)
        length = np.where(length < 1e-12, 1.0, length)
        move = disp * (np.minimum(length, t) / length)[:, None]
        P += move
        t -= dt
        if np.linalg.norm(move) / n < threshold:
            break
    return P


def stress_majorization(g, pos0=None, tolerance=1e-4, max_iterations=1000, length=1.0):
    """Localized (Gauss-Seidel) majorization in vertices order, weights d^-2, from the circular
    layout of radius the mean edge length (every edge has length `length` here); stops when the
    relative stress decrease is below tolerance."""
    n = g.n
    D = target_distances(g, length)
    P = np.array(pos0 if pos0 is not None else circular(n, radius=length), float).reshape(n, 2)
    if n <= 1:
        return P, 0.0, 0
    W = np.zeros_like(D)
    off = ~np.eye(n, dtype=bool)
    W[off] = D[off] ** -2.0
    s = raw_stress(D, P)
    it = 0
    for it in range(1, max_iterations + 1):
        for i in range(n):
            diff = P[i] - P
            e = np.linalg.norm(diff, axis=1)
            e[i] = 1.0
            e = np.where(e < 1e-12, 1e-12, e)
            num = (W[i, :, None] * (P + D[i, :, None] * diff / e[:, None])).sum(axis=0)
            P[i] = num / W[i].sum()
        s2 = raw_stress(D, P)
        if s - s2 < tolerance * s:
            s = s2
            break
        s = s2
    return P, s, it


# ============================================================================ phase 2 references

def spectral(g):
    """Eigenvectors 2 and 3 (ascending eigenvalue) of L = D - A (parallel edges add weight,
    loops ignored), unit length, sign: the first component, in index order, whose magnitude is at
    least 1e-4 of the largest is positive (SpectralGraphTheory's rule for fiedlerVector(), so x is
    fiedlerVector())."""
    n = g.n
    A = np.zeros((n, n))
    for u, v in g.edges:
        if u != v:
            A[u, v] += 1
            A[v, u] += 1
    L = np.diag(A.sum(axis=1)) - A
    w, V = np.linalg.eigh(L)
    cols = []
    for j in (1, 2):
        c = V[:, j].copy()
        big = max(abs(x) for x in c)
        for x in c:
            if abs(x) >= 1e-4 * big:
                if x < 0:
                    c = -c
                break
        cols.append(c)
    return [(float(cols[0][i]), float(cols[1][i])) for i in range(n)], w


# ============================================================================ shell, spiral, columns, scaling

def shell(n, shells=None, rotation=None, radius=1.0, center=(0.0, 0.0)):
    """Shell k of s on radius (k + 1) r / s (k r / s when the first shell has one vertex); the j-th
    of c vertices at angle 2 pi j / c + (k + 1) rotation, rotation pi / s by default; one vertex at
    the centre."""
    pos = [center] * n
    if n <= 1:
        return pos
    if shells is None:
        shells = [list(range(n))]
    s = len(shells)
    bump = radius / s
    turn = math.pi / s if rotation is None else rotation
    r = 0.0 if len(shells[0]) == 1 else bump
    first = turn
    for shell_ in shells:
        step = TAU / max(len(shell_), 1)
        for j, v in enumerate(shell_):
            a = j * step + first
            pos[v] = (center[0] + r * math.cos(a), center[1] + r * math.sin(a))
        r += bump
        first += turn
    return pos


def spiral(n, resolution=0.35, equidistant=False):
    if n == 1:
        return [(0.0, 0.0)]
    out = []
    if equidistant:
        theta = resolution
        theta += 1 / (0.5 * theta)
        for _ in range(n):
            rho = 0.5 * theta
            theta += 1 / rho
            out.append((math.cos(theta) * rho, math.sin(theta) * rho))
    else:
        for i in range(n):
            out.append((i * math.cos(resolution * i), i * math.sin(resolution * i)))
    return out


def bipartite(n, left, aspect=4 / 3):
    pos = [None] * n
    right = [v for v in range(n) if v not in set(left)]
    for column, x in ((list(left), -aspect / 2), (right, aspect / 2)):
        k = len(column)
        step = 1 / (k - 1) if k > 1 else 0
        for j, v in enumerate(column):
            pos[v] = (x, (1.0 if j == k - 1 and k > 1 else j * step) - 0.5)
    return pos


def columns(layer, sequence):
    """multipartiteLayout's columns: `sequence` grouped by ascending layer."""
    n = len(layer)
    groups = []
    for v in sequence:
        if groups and layer[groups[-1][0]] == layer[v]:
            groups[-1].append(v)
        else:
            groups.append([v])
    pos = [None] * n
    for c, grp in enumerate(groups):
        for j, v in enumerate(grp):
            pos[v] = (c - (len(groups) - 1) / 2, j - (len(grp) - 1) / 2)
    return pos


def bfs_hops(g, start):
    adj = [[] for _ in range(g.n)]
    for u, v in g.edges:
        adj[u].append(v)
        if u != v:
            adj[v].append(u)
    hops = [-1] * g.n
    hops[start] = 0
    q = deque([start])
    while q:
        v = q.popleft()
        for w in adj[v]:
            if hops[w] < 0:
                hops[w] = hops[v] + 1
                q.append(w)
    return hops


def bfs_order(g, start):
    adj = [[] for _ in range(g.n)]
    for u, v in g.edges:
        adj[u].append(v)
        if u != v:
            adj[v].append(u)
    seen, order, q = {start}, [start], deque([start])
    while q:
        v = q.popleft()
        for w in adj[v]:
            if w not in seen:
                seen.add(w)
                order.append(w)
                q.append(w)
    return order


def signed(c):
    big = max(abs(x) for x in c)
    for x in c:
        if abs(x) >= 1e-4 * big:
            return -c if x < 0 else c
    return c


def scaling(g, length=None):
    """Classical scaling of the shortest-path distances (hops, or Dijkstra over `length` per
    position); 1 + mean length * sqrt(n) between components; axes signed as the spectral ones."""
    n = g.n
    if n <= 1:
        return [(0.0, 0.0)] * n
    lengths = [length[k] if length else 1.0 for k, (u, v) in enumerate(g.edges) if u != v]
    mean = sum(lengths) / len(lengths) if lengths else 1.0
    G = nx.Graph()
    G.add_nodes_from(range(n))
    for k, (u, v) in enumerate(g.edges):
        if u != v:
            w = length[k] if length else 1.0
            if not G.has_edge(u, v) or G[u][v]["w"] > w:
                G.add_edge(u, v, w=w)
    D = np.full((n, n), 1 + mean * math.sqrt(n))
    for s_, dist in nx.all_pairs_dijkstra_path_length(G, weight="w"):
        for t, d_ in dist.items():
            D[s_, t] = d_
    J = np.eye(n) - np.ones((n, n)) / n
    w, V = np.linalg.eigh(-0.5 * J @ (D * D) @ J)
    x = signed(V[:, -1].copy()) * math.sqrt(max(w[-1], 0))
    y = signed(V[:, -2].copy()) * math.sqrt(max(w[-2], 0))
    return [(float(x[i]), float(y[i])) for i in range(n)], w, D


# ============================================================================ formatting

def num(x, digits=None):
    if digits is not None:
        x = round(x, digits)
    if x == 0:
        x = 0.0
    if float(x).is_integer() and abs(x) < 1e15:
        return f"{x:.1f}"
    return repr(float(x))


def pts(ps, digits=None):
    return "[" + ", ".join(f"({num(x, digits)}, {num(y, digits)})" for x, y in ps) + "]"


# ============================================================================ rows

ROWS = []
DISAGREE = defaultdict(int)
CHECKS = defaultdict(int)


def row(group, case, inp, op, expected):
    ROWS.append([None, group, case, inp, op, expected])


def note(lib, why):
    DISAGREE[(lib, why)] += 1


def close(a, b, tol):
    return len(a) == len(b) and all(abs(p[0] - q[0]) <= tol and abs(p[1] - q[1]) <= tol for p, q in zip(a, b))


# ---------------------------------------------------------------------------- Drawing

def drawing_rows():
    G_ = "Drawing"
    row(G_, "empty drawing: no vertices", "`Drawing<Int>()`", "count", "0")
    row(G_, "empty drawing: no bounding box", "`Drawing<Int>()`", "boundingBox", "nil")
    row(G_, "empty drawing: rescaled stays empty", "`Drawing<Int>()`", "rescaled()", "[]")
    d = [(0.0, 0.0), (2.0, 1.0)]
    row(G_, "positions in vertices order", "`Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])`", "positions", pts(d))
    row(G_, "position(of:) reads by vertex", "`Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])`", "position(of: 3)", "(2.0, 1.0)")
    row(G_, "setPosition(_:of:) writes by vertex", "`Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])`", "setPosition((7, -1), of: 5); positions", "[(7.0, -1.0), (2.0, 1.0)]")
    row(G_, "position(of:) on a missing vertex", "`Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])`", "position(of: 4)", "**trap**")
    row(G_, "position(checked:) on a missing vertex", "`Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])`", "position(checked: 4)", "throws VertexNotFound")
    row(G_, "position(checked:) on a vertex", "`Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])`", "position(checked: 5)", "(0.0, 0.0)")
    row(G_, "vertices and positions of different lengths", "`Drawing(vertices: [5, 3], positions: [(0, 0)])`", "init", "**trap**")
    row(G_, "duplicate vertex", "`Drawing(vertices: [5, 5], positions: [(0, 0), (1, 1)])`", "init", "**trap**")
    row(G_, "elements are (vertex, position) pairs in order", "`Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])`", "Array(self)", "[(5, (0.0, 0.0)), (3, (2.0, 1.0))]")
    row(G_, "equal when vertices and positions are equal in order", "`Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])` vs `Drawing(vertices: [3, 5], positions: [(2, 1), (0, 0)])`", "==", "false")
    bb = bounding_box(d)
    row(G_, "bounding box", "`Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])`", "boundingBox", f"(min: {pts([bb[0]])[1:-1]}, max: {pts([bb[1]])[1:-1]})")
    cases = [
        ("rescaled: centred, largest |coordinate| = 1", [(0.0, 0.0), (2.0, 1.0)], 1.0, (0.0, 0.0)),
        ("rescaled: scale 3", [(0.0, 0.0), (2.0, 1.0)], 3.0, (0.0, 0.0)),
        ("rescaled: centre (10, -2)", [(0.0, 0.0), (2.0, 1.0)], 1.0, (10.0, -2.0)),
        ("rescaled: three points, the y extent decides", [(0.0, 0.0), (1.0, 4.0), (2.0, -4.0)], 1.0, (0.0, 0.0)),
        ("rescaled: one point goes to the centre", [(3.0, 4.0)], 1.0, (0.0, 0.0)),
        ("rescaled: coincident points go to the centre", [(3.0, 4.0), (3.0, 4.0)], 2.0, (1.0, 1.0)),
        ("rescaled: square", [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)], 1.0, (0.0, 0.0)),
    ]
    for case, p, s, c in cases:
        got = rescaled(p, s, c)
        if len(p) > 0:
            ref = nx.rescale_layout(np.array(p, float), scale=s) + np.array(c)
            assert close(got, [tuple(r) for r in ref], 1e-12), (case, got, ref)
            CHECKS["rescale vs NetworkX"] += 1
        vs = list(range(len(p)))
        row(G_, case, f"`Drawing(vertices: {vs}, positions: {pts(p)})`", f"rescaled(scale: {num(s)}, center: {pts([c])[1:-1]})", pts(got))


# ---------------------------------------------------------------------------- circular

def circular_rows():
    G_ = "Circular"
    for n in (0, 1, 2, 3, 4, 6):
        spec = f"U: n={n};" + (" C(" + ",".join(map(str, range(n))) + ")" if n >= 3 else "")
        got = circular(n)
        if n > 0:
            ref = nx.circular_layout(parse(spec).simple_nx())
            refp = [tuple(ref[i]) for i in range(n)]
            if not close(got, refp, 1e-12):
                note("NetworkX circular_layout", "computes in float32: positions off by up to 1e-7")
                assert close(got, refp, 1e-6)
            CHECKS["circular vs NetworkX (1e-6)"] += 1
        row(G_, f"{n} vertices" + (": the centre" if n == 1 else ""), f"`{spec}`", "circularLayout()", pts(got, 12))
    got = circular(4, 2.0, (1.0, -1.0))
    row(G_, "radius 2, centre (1, -1)", "`U: n=4;`", "circularLayout(radius: 2, center: (1, -1))", pts(got, 12))
    got = circular(3, 1.0, (5.0, 5.0))
    row(G_, "edges do not matter: vertices order only", "`U: n=3; 0-2, 2-1`", "circularLayout(center: (5, 5))", pts(got, 12))
    row(G_, "directed graph through its undirected view", "`D: n=3; 0>1`", "undirectedView.circularLayout()", pts(circular(3), 12))
    row(G_, "negative radius", "`U: n=3;`", "circularLayout(radius: -1)", "**trap**")
    row(G_, "NaN centre", "`U: n=3;`", "circularLayout(center: (.nan, 0))", "**trap**")


# ---------------------------------------------------------------------------- trees

TREES = [
    ("one vertex", "T: [nil]"),
    ("two vertices", "T: [nil, 0]"),
    ("path of 4", "T: [nil, 0, 1, 2]"),
    ("star K1,3: root over the middle child", "T: [nil, 0, 0, 0]"),
    ("star K1,4: even fan, root over the gap", "T: [nil, 0, 0, 0, 0]"),
    ("binary tree of height 2", "T: bal(2,2)"),
    ("ternary tree of height 2", "T: bal(3,2)"),
    ("binary tree of height 4", "T: bal(2,4)"),
    ("left child has two leaves, right is a leaf", "T: [nil, 0, 0, 1, 1]"),
    ("left leaf, right child has two leaves", "T: [nil, 0, 0, 2, 2]"),
    ("igraph's example shape: one deep child among leaves", "T: [nil, 0, 0, 0, 1, 1]"),
    ("two chains under a three-way root", "T: [nil, 0, 0, 0, 1, 4, 3, 6]"),
    ("Walker's spreading: leaves between two wide subtrees are spaced evenly",
     "T: [nil, 0, 0, 0, 0, 1, 1, 1, 4, 4, 4]"),
    ("Walker's spreading, deep: wide subtrees meet two levels down",
     "T: [nil, 0, 0, 0, 0, 1, 4, 5, 5, 5, 6, 6, 6]"),
    ("a small subtree between two large ones moves to the middle",
     "T: [nil, 0, 0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 7, 7, 8, 8]"),
    ("caterpillar", "T: [nil, 0, 1, 2, 0, 1, 2, 3]"),
    ("broom: a path then a fan", "T: [nil, 0, 1, 2, 2, 2, 2]"),
    ("root is not vertex 0", "T: [2, 2, nil, 1]"),
    ("random tree, 20 vertices", "T: lcgtree(20,1)"),
    ("random tree, 40 vertices", "T: lcgtree(40,7)"),
    ("random tree, 60 vertices", "T: lcgtree(60,3)"),
]


def tree_rows():
    G_ = "Tree"
    for case, spec in TREES:
        par = parse_tree(spec)
        pos = reingold_tilford(par)
        bad = tree_invariants(par, pos)
        assert not bad, (case, bad)
        CHECKS["tree invariants"] += 1
        # igraph
        n = len(par)
        root = par.index(None)
        edges = [(par[v], v) for v in range(n) if par[v] is not None]
        gi = ig.Graph(n=n, edges=edges)
        if n == 1:
            ip = [(0.0, 0.0)]
        else:
            ip = [tuple(p) for p in gi.layout_reingold_tilford(root=[root], mode="all").coords]
        if close(pos, ip, 1e-9):
            CHECKS["Reingold-Tilford equal to igraph"] += 1
        else:
            note("igraph layout_reingold_tilford", "places parents differently: not centred over the outer children (Walker and Buchheim et al. centre them)")
        row(G_, case, f"`{spec}`", "reingoldTilfordLayout()", pts(pos))
    # mirror symmetry (Walker's property): a reflected tree draws as the reflection
    for case, spec in TREES[12:15]:
        par = parse_tree(spec)
        pos = reingold_tilford(par)
        n = len(par)
        par2, new = mirrored(par)
        pos2 = reingold_tilford(par2)
        refl = [(-pos[v][0], pos[v][1]) for v in range(n)]
        assert close([pos2[new[v]] for v in range(n)], refl, 1e-9), case
        CHECKS["mirror property"] += 1
        row(G_, "mirror image draws as the reflection: " + case, f"`T: {par2}`".replace("None", "nil"),
            "reingoldTilfordLayout()", pts(pos2))
    row(G_, "isomorphic subtrees are drawn identically (translated)", "`T: bal(2,3)`", "x(subtree of 1) − x(1) == x(subtree of 2) − x(2)", "true")
    for case, spec in [("one vertex", "T: [nil]"), ("star K1,4", "T: [nil, 0, 0, 0, 0]"),
                       ("igraph's example shape", "T: [nil, 0, 0, 0, 1, 1]"), ("binary tree of height 3", "T: bal(2,3)"),
                       ("two chains under a three-way root", "T: [nil, 0, 0, 0, 1, 4, 3, 6]"),
                       ("random tree, 20 vertices", "T: lcgtree(20,1)")]:
        par = parse_tree(spec)
        got = rt_circular(par)
        n = len(par)
        root = par.index(None)
        edges = [(par[v], v) for v in range(n) if par[v] is not None]
        if n > 1:
            ip = [tuple(p) for p in ig.Graph(n=n, edges=edges).layout_reingold_tilford_circular(root=[root], mode="all").coords]
            if close(got, ip, 1e-9):
                CHECKS["circular tree equal to igraph"] += 1
            else:
                note("igraph layout_reingold_tilford_circular", "inherits its Reingold-Tilford differences")
        row(G_, "circular: " + case, f"`{spec}`", "reingoldTilfordCircularLayout()", pts(got, 12))


# ---------------------------------------------------------------------------- Sugiyama

DAGS = [
    ("empty graph", "D: n=0;"),
    ("one vertex", "D: n=1;"),
    ("isolated vertices share layer 0, in vertices order", "D: n=3;"),
    ("one arc", "D: 0>1"),
    ("path", "D: P(0,1,2,3)"),
    ("diamond", "D: 0>1, 0>2, 1>3, 2>3"),
    ("diamond with a long arc 0>3 (one bend)", "D: 0>1, 0>2, 1>3, 2>3, 0>3, 3>4"),
    ("long arc over two layers (two bends)", "D: P(0,1,2,3), 0>3"),
    ("two sources, one sink", "D: 0>2, 1>2"),
    ("crossing in the initial order is removed", "D: 0>3, 1>2"),
    ("K2,2 between layers: one crossing is unavoidable", "D: 0>2, 0>3, 1>2, 1>3"),
    ("K3,3 between layers: 9 crossings at least", "D: 0>3, 0>4, 0>5, 1>3, 1>4, 1>5, 2>3, 2>4, 2>5"),
    ("binary out-tree", "D: 0>1, 0>2, 1>3, 1>4, 2>5, 2>6"),
    ("three layers, crossings in both gaps", "D: 0>4, 1>3, 2>5, 3>8, 4>6, 5>7"),
    ("parallel arcs: two edges, no bends", "D: 0>1, 0>1"),
    ("self-loop ignored in layering, no bends", "D: 0>0, 0>1"),
    ("2-cycle: one arc reversed", "D: 0>1, 1>0"),
    ("3-cycle: one arc reversed", "D: C(0,1,2)"),
    ("cycle with a tail", "D: C(0,1,2,3), 3>4, 4>5"),
    ("two 3-cycles sharing a vertex", "D: C(0,1,2), C(0,3,4)"),
    ("tournament on 4 vertices with one cycle", "D: 0>1, 1>2, 2>0, 0>3, 1>3, 2>3"),
    ("transitive tournament on 4", "D: 0>1, 0>2, 0>3, 1>2, 1>3, 2>3"),
    ("arcs given against vertex order", "D: n=4; 3>2, 2>1, 1>0"),
    ("two components", "D: 0>1, 2>3, 2>4"),
    ("random DAG, 12 vertices, 18 arcs", "D: lcgdag(12,18,1)"),
    ("random DAG, 15 vertices, 25 arcs", "D: lcgdag(15,25,2)"),
    ("random digraph with cycles, 10 vertices, 16 arcs", "D: lcggraph(10,16,3)"),
]


def igraph_span(g):
    y = [p[1] for p in g.ig().layout_sugiyama().coords[: g.n]]
    return round(sum(abs(y[v] - y[u]) for u, v in g.edges if u != v))


def res_span(g, res):
    return res["span"] if "span" in res else sum(abs(res["layer"][v] - res["layer"][u]) for u, v in g.edges if u != v)


def sugiyama_rows():
    G_ = "Layered"
    for case, spec in DAGS:
        g = parse(spec)
        res = sugiyama(g.n, g.edges)
        if res["reversed"]:
            row(G_, case + ": reversed edges (Eades–Lin–Smyth)", f"`{spec}`", "sugiyamaLayout().reversedEdges", str(res["reversed"]))
        if g.n:
            ispan = igraph_span(g)
            if ispan == res_span(g, res):
                CHECKS["Sugiyama total span equal to igraph's"] += 1
            elif not res["reversed"]:
                assert ispan > res_span(g, res), case
                note("igraph layout_sugiyama", "total span above the optimum on a DAG (it keeps sources on layer 0)")
            else:
                note("igraph layout_sugiyama", "different total span on a cyclic graph (another feedback arc set)")
        if res["layer"] is None:
            row(G_, case + ": total edge span (optimal layering not unique; layers and positions not pinned)", f"`{spec}`",
                "sugiyamaLayout() Σ span", f"#{res['span']}")
            continue
        bad = sugiyama_invariants(g.n, g.edges, res)
        assert not bad, (case, bad)
        CHECKS["Sugiyama invariants"] += 1
        row(G_, case + ": layers", f"`{spec}`", "sugiyamaLayout() layer(of:) in vertices order", str(res["layer"]))
        row(G_, case + ": crossings", f"`{spec}`", "sugiyamaLayout().crossingCount", f"#{res['crossings']}")
        row(G_, case + ": positions", f"`{spec}`", "sugiyamaLayout().drawing.positions", pts(res["pos"]))
        if any(res["bends"]):
            b = "; ".join(f"{e}: {pts(bs)}" for e, bs in enumerate(res["bends"]) if bs)
            row(G_, case + ": bends", f"`{spec}`", "sugiyamaLayout() bends(ofEdgeAt:) where non-empty", b)
    # caller layers
    g = parse("D: 0>1, 0>2, 1>3")
    res = sugiyama(g.n, g.edges, layers=[0, 2, 1, 3])
    row(G_, "caller layers: a long arc and its bend", "`D: 0>1, 0>2, 1>3`", "sugiyamaLayout(layers: [0, 2, 1, 3]) positions", pts(res["pos"]))
    row(G_, "caller layers: bends", "`D: 0>1, 0>2, 1>3`", "sugiyamaLayout(layers: [0, 2, 1, 3]) bends(ofEdgeAt: 0)", pts(res["bends"][0]))
    res = sugiyama(g.n, g.edges, layers=[1, 0, 1, 1])
    row(G_, "caller layers: an upward arc is reversed, a flat arc has no segment", "`D: 0>1, 0>2, 1>3`",
        "sugiyamaLayout(layers: [1, 0, 1, 1]).reversedEdges", str(res["reversed"]))
    row(G_, "caller layers: negative layer", "`D: 0>1`", "sugiyamaLayout(layers: [-1, 0])", "**trap**")
    row(G_, "maxIterations: 0 keeps the initial order", "`D: 0>3, 1>2`", "sugiyamaLayout(maxIterations: 0).crossingCount", f"#{sugiyama(4, [(0, 3), (1, 2)], max_iterations=0)['crossings']}")
    row(G_, "DirectedAcyclicGraph: no edge is reversed", "`D: lcgdag(15,25,2)` as `DirectedAcyclicGraph`", "sugiyamaLayout().reversedEdges", "[]")
    row(G_, "layer(of:) on a missing vertex", "`D: 0>1`", "sugiyamaLayout().layer(of: 9)", "**trap**")
    row(G_, "bends(ofEdgeAt:) on a missing edge", "`D: 0>1`", "sugiyamaLayout().bends(ofEdgeAt: 5)", "**trap**")


# ---------------------------------------------------------------------------- force-directed

QUALITY_GRAPHS = [
    ("cycle C12", "U: C(0,1,2,3,4,5,6,7,8,9,10,11)"),
    ("grid 5 x 5", "U: grid(5,5)"),
    ("binary tree of height 4 (as a graph)", "U: " + ", ".join(f"{(v - 1) // 2}-{v}" for v in range(1, 31))),
    ("cube Q4", "U: Q(4)"),
    ("Petersen", "U: petersen"),
    ("random graph, 40 vertices, 60 edges", "U: lcggraph(40,60,5)"),
]
SEEDS = range(1, 21)


def fr_rows():
    G_ = "ForceDirected"
    for n, seed in [(3, 1), (5, 42)]:
        p, draws = initial_random(n, seed)
        row(G_, f"initial positions: x then y per vertex, uniform in [0, 1), seed {seed}", f"`U: n={n};`",
            f"fruchtermanReingoldLayout(iterations: 0, using: &Xoshiro256StarStar(seed: {seed}))", pts(p))
        row(G_, f"initial positions: exactly 2n draws, seed {seed}", f"`U: n={n};`",
            f"draws by fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: {seed}))", f"#{draws}")
    row(G_, "empty graph: empty drawing, no draws", "`U: n=0;`", "fruchtermanReingoldLayout(using: &g)", "[] (#0 draws)")
    row(G_, "one vertex: stays at its initial position", "`U: n=1;`", "fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: 1))", pts(initial_random(1, 1)[0]))
    row(G_, "same seed, same drawing", "`U: grid(5,5)`", "two calls with Xoshiro256StarStar(seed: 9)", "equal")
    row(G_, "initial: drawing missing a vertex", "`U: P(0,1,2)`", "fruchtermanReingoldLayout(initial: Drawing(vertices: [0, 1], …))", "**trap**")
    row(G_, "step() after the last iteration changes nothing", "`U: P(0,1,2)`", "FruchtermanReingoldLayout(iterations: 2): step() x 3", "isFinished; drawing equal after steps 2 and 3")
    row(G_, "step() count: iterations steps, or fewer when converged", "`U: grid(5,5)`", "FruchtermanReingoldLayout(iterations: 50).iteration after run", "≤ 50")
    row(G_, "iterations: -1", "`U: P(0,1,2)`", "fruchtermanReingoldLayout(iterations: -1, using: &g)", "**trap**")
    row(G_, "two vertices joined by an edge end at distance k (the optimal distance)", "`U: 0-1`",
        "fruchtermanReingoldLayout(iterations: 500, optimalDistance: 1, using: &Xoshiro256StarStar(seed: 1)) distance",
        "1.0 ± 1e-3")
    # equilibrium check in the model
    g = parse("U: 0-1")
    P = fruchterman_reingold(g, initial_random(2, 1)[0], iterations=500, k=1.0)
    assert abs(np.linalg.norm(P[0] - P[1]) - 1.0) < 1e-3
    CHECKS["FR equilibrium"] += 1
    for case, spec in QUALITY_GRAPHS:
        g = parse(spec)
        D = hop_distances(g)
        ours = [normalized_stress(g, fruchterman_reingold(g, initial_random(g.n, s)[0]), D) for s in SEEDS]
        gn = g.simple_nx()
        theirs = [normalized_stress(g, [nx.spring_layout(gn, seed=s, method="force")[i] for i in range(g.n)], D) for s in SEEDS]
        mo, mt = statistics.median(ours), statistics.median(theirs)
        thr = math.ceil(1.10 * max(mt, 1e-3) * 1000) / 1000
        if mo > thr:
            note("model", f"FR median stress {mo:.4f} above 1.1 x NetworkX on {case}")
        else:
            CHECKS["FR quality threshold reachable"] += 1
        row(G_, f"Fruchterman–Reingold quality, {case} (median normalized stress over seeds 1…20; NetworkX {mt:.4f}, model {mo:.4f})",
            f"`{spec}`", "fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s))", f"≤ {thr}")
    for case, spec in [("cycle C12", QUALITY_GRAPHS[0][1]), ("binary tree of height 4", QUALITY_GRAPHS[2][1])]:
        g = parse(spec)
        cr = [segment_crossings(g, fruchterman_reingold(g, initial_random(g.n, s)[0])) for s in SEEDS]
        gn = g.simple_nx()
        crn = [segment_crossings(g, [nx.spring_layout(gn, seed=s, method="force")[i] for i in range(g.n)]) for s in SEEDS]
        thr = max(statistics.median(crn), statistics.median(cr))
        row(G_, f"Fruchterman–Reingold crossings, {case} (median over seeds 1…20; NetworkX {statistics.median(crn):g}, model {statistics.median(cr):g})",
            f"`{spec}`", "fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s))", f"≤ {thr:g}")
    # Barnes-Hut: same quality within a margin of exact
    for case, spec in QUALITY_GRAPHS[1:2] + QUALITY_GRAPHS[5:6]:
        g = parse(spec)
        D = hop_distances(g)
        ours = statistics.median(normalized_stress(g, fruchterman_reingold(g, initial_random(g.n, s)[0]), D) for s in SEEDS)
        thr = math.ceil(1.15 * ours * 1000) / 1000
        row(G_, f"Barnes–Hut (θ = 1.2) within 15% of exact repulsion, {case} (exact model {ours:.4f})", f"`{spec}`",
            "fruchtermanReingoldLayout(barnesHutTheta: 1.2, using: &Xoshiro256StarStar(seed: s)), median", f"≤ {thr}")
    row(G_, "Barnes–Hut θ = 0 is exact repulsion", "`U: grid(5,5)`", "fruchtermanReingoldLayout(barnesHutTheta: 0, …) == fruchtermanReingoldLayout(…)", "equal up to 1e-9")
    row(G_, "Barnes–Hut θ < 0", "`U: P(0,1,2)`", "fruchtermanReingoldLayout(barnesHutTheta: -1, using: &g)", "**trap**")


def stress_rows():
    G_ = "Stress"
    for case, spec in [("one vertex", "U: n=1;"), ("one edge", "U: 0-1"), ("path of 3", "U: P(0,1,2)"),
                       ("cycle C6", "U: C(0,1,2,3,4,5)"), ("K4", "U: K(4)")] + QUALITY_GRAPHS + [
                       ("two components: a triangle and an edge", "U: C(0,1,2), 3-4")]:
        g = parse(spec)
        P, s, it = stress_majorization(g)
        ns = normalized_stress(g, P) if g.n > 1 else 0.0
        if g.n > 1 and nx.is_connected(g.simple_nx()):
            kk = nx.kamada_kawai_layout(g.simple_nx())
            nk = normalized_stress(g, [kk[i] for i in range(g.n)])
            bound = 1.02 * nk + 1e-4
            extra = ""
            if ns > bound:
                # The default tolerance (1e-4) stops on a plateau above Kamada-Kawai;
                # the row bounds the model's own value + 1%, and says so.
                note("model", f"stress above Kamada-Kawai at the default tolerance on {case}")
                bound = 1.01 * ns + 1e-4
                P5, _, _ = stress_majorization(g, tolerance=1e-5)
                extra = f"; above it at the default tolerance, {normalized_stress(g, P5):.4f} at tolerance 1e-5"
            else:
                CHECKS["stress <= 1.02 x NetworkX Kamada-Kawai"] += 1
            exp = (f"stress ≈ {s:.6g} (±1%)" if s >= 1e-3 else "stress ≤ 0.001") + \
                f", normalized ≤ {math.ceil(bound * 1e4) / 1e4} (NetworkX Kamada–Kawai {nk:.4f}{extra})"
        else:
            exp = f"stress ≈ {s:.6g} (±1%)"
        if g.n <= 2:
            exp = f"{pts([tuple(p) for p in P], 12)}; stress {num(s, 12)}"
        row(G_, case, f"`{spec}`", "stressMajorizationLayout()", exp)
    row(G_, "stress never increases between steps", "`U: grid(5,5)`", "StressMajorizationLayout: stress after each step()", "non-increasing")
    row(G_, "initial drawing is used as given (no randomness)", "`U: grid(5,5)`", "two calls", "equal")
    # The default start is scaled by the mean edge length, and the update is homogeneous, so every
    # iterate with lengths 2 is exactly twice the unit one.
    g = parse("U: C(0,1,2,3,4,5)")
    P1, s1, it1 = stress_majorization(g)
    P2, s2, it2 = stress_majorization(g, length=2.0)
    assert np.array_equal(P2, 2 * P1) and it1 == it2
    CHECKS["stress: edge length 2 doubles the drawing exactly"] += 1
    row(G_, "edge length 2 doubles the drawing", "`U: C(0,1,2,3,4,5)`", "stressMajorizationLayout(edgeLength: { _ in 2 }) vs default", "positions × 2 (exact)")
    row(G_, "edge length ≤ 0", "`U: 0-1`", "stressMajorizationLayout(edgeLength: { _ in 0 })", "**trap**")
    row(G_, "tolerance < 0", "`U: 0-1`", "stressMajorizationLayout(tolerance: -1)", "**trap**")


# ---------------------------------------------------------------------------- phase 2

def more_rows():
    G_ = "Spectral"
    for case, spec in [("path of 5", "U: P(0,1,2,3,4)"), ("grid 3 x 4", "U: grid(3,4)"),
                       ("random graph, 12 vertices, 20 edges", "U: lcggraph(12,20,9)")]:
        g = parse(spec)
        if not nx.is_connected(g.simple_nx()):
            continue
        p, w = spectral(g)
        if not (w[1] - w[0] > 1e-6 and w[2] - w[1] > 1e-6 and w[3] - w[2] > 1e-6):
            continue
        ref = nx.spectral_layout(g.nx())
        mine = rescaled(p)
        refp = [tuple(ref[i]) for i in range(g.n)]
        flips = [(sx, sy) for sx in (1, -1) for sy in (1, -1)]
        assert any(close([(sx * x, sy * y) for x, y in mine], refp, 1e-6) for sx, sy in flips), case
        CHECKS["spectral vs NetworkX up to sign"] += 1
        row(G_, f"spectral: {case} (Fiedler vector, then the third)", f"`{spec}`", "spectralLayout()", pts(p, 9))
    row(G_, "spectral: path of 5 has x = the Fiedler vector, y = the next eigenvector", "`U: P(0,1,2,3,4)`", "spectralLayout() vs fiedlerVector()", "x equal")
    g = parse("U: P(0,1,2), 1-3, 3-4")
    ref = nx.bfs_layout(g.simple_nx(), 0)
    mine = rescaled(columns([bfs_hops(g, 0)[v] for v in range(g.n)], bfs_order(g, 0)))
    assert close(mine, [tuple(ref[i]) for i in range(g.n)], 1e-12)
    CHECKS["bfs and multipartite vs NetworkX (1e-12)"] += 1
    row("BFS", "bfs layout (NetworkX bfs_layout, start 0)", "`U: P(0,1,2), 1-3, 3-4`", "bfsLayout(start: 0).rescaled()", pts([tuple(ref[i]) for i in range(g.n)], 12))
    gn = nx.Graph()
    gn.add_nodes_from(range(5))
    gn.add_edges_from([(0, 2), (1, 3), (2, 4)])
    for v, l in zip(range(5), [0, 0, 1, 1, 2]):
        gn.nodes[v]["subset"] = l
    ref = nx.multipartite_layout(gn)
    mine = rescaled(columns([0, 0, 1, 1, 2], [0, 1, 2, 3, 4]))
    assert close(mine, [tuple(ref[i]) for i in range(5)], 1e-12)
    CHECKS["bfs and multipartite vs NetworkX (1e-12)"] += 1
    row("Multipartite", "multipartite layout (NetworkX multipartite_layout)", "`U: n=5; 0-2, 1-3, 2-4` layers [0, 0, 1, 1, 2]",
        "multipartiteLayout(layer: { [0, 0, 1, 1, 2][$0] }).rescaled()", pts([tuple(ref[i]) for i in range(5)], 12))
    for case, spec in QUALITY_GRAPHS[1:2] + QUALITY_GRAPHS[5:6]:
        g = parse(spec)
        D = hop_distances(g)
        gn = g.simple_nx()
        theirs = statistics.median(normalized_stress(g, [nx.forceatlas2_layout(gn, seed=s)[i] for i in range(g.n)], D) for s in SEEDS)
        row("ForceAtlas2", f"ForceAtlas2 quality, {case} (NetworkX median {theirs:.4f})", f"`{spec}`",
            "forceAtlas2Layout(using: &Xoshiro256StarStar(seed: s)), median over 1…20", f"≤ {math.ceil(1.10 * theirs * 1000) / 1000}")


def layout_rows():
    G_ = "Shell"
    for spec, shells, label in [("U: n=4; 0-1", None, "one shell by default, starting at angle pi"),
                                ("U: P(0,1,2,3)", [[0], [1, 2, 3]], "a first shell of one vertex at the centre")]:
        g = parse(spec)
        got = shell(g.n, shells)
        ref = nx.shell_layout(g.simple_nx(), nlist=shells)
        if not close(got, [tuple(ref[i]) for i in range(g.n)], 1e-12):
            note("NetworkX shell_layout", "computes the angles in float32: positions off by up to 1e-7")
            assert close(got, [tuple(ref[i]) for i in range(g.n)], 1e-6)
        CHECKS["shell vs NetworkX (1e-6)"] += 1
        op = "shellLayout()" if shells is None else f"shellLayout(shells: {shells})"
        row(G_, label, f"`{spec}`", op, pts(got, 12))
    g = parse("U: n=3;")
    row(G_, "radius 3, centre (10, -1), rotation 0, an empty shell keeps its radius", "`U: n=3;`",
        "shellLayout(shells: [[2, 0], [], [1]], rotation: 0, radius: 3, center: (10, -1))",
        pts(shell(3, [[2, 0], [], [1]], 0.0, 3.0, (10.0, -1.0)), 12))
    row(G_, "one vertex at the centre", "`U: n=1; 0-0`", "shellLayout(center: (2, 3))", pts([(2.0, 3.0)]))
    row(G_, "a vertex in two shells", "`U: n=3;`", "shellLayout(shells: [[0, 1], [1, 2]])", "**trap**")
    row(G_, "a vertex in no shell", "`U: n=3;`", "shellLayout(shells: [[0, 1]])", "**trap**")
    G_ = "Spiral"
    for spec, eq in [("U: P(0,1,2,3)", False), ("U: n=6;", True)]:
        g = parse(spec)
        got = spiral(g.n, equidistant=eq)
        ref = nx.spiral_layout(g.simple_nx(), equidistant=eq)
        assert close(rescaled(got), [tuple(ref[i]) for i in range(g.n)], 1e-12)
        CHECKS["spiral rescaled vs NetworkX (1e-12)"] += 1
        call = "spiralLayout(equidistant: true)" if eq else "spiralLayout()"
        row(G_, ("equidistant: " if eq else "") + f"{g.n} vertices", f"`{spec}`", call, pts(got, 12))
        row(G_, ("equidistant, " if eq else "") + "rescaled: NetworkX spiral_layout", f"`{spec}`", call + ".rescaled()", pts(rescaled(got), 12))
    row(G_, "zero resolution with equidistant", "`U: n=3;`", "spiralLayout(resolution: 0, equidistant: true)", "**trap**")
    G_ = "Bipartite"
    g = parse("U: " + ", ".join(f"{u}-{v}" for u in range(3) for v in range(3, 6)))
    got = bipartite(6, [3, 4, 5])
    ref = nx.bipartite_layout(g.simple_nx(), nodes=[3, 4, 5])
    assert close(rescaled(got), [tuple(ref[i]) for i in range(6)], 1e-12)
    CHECKS["bipartite rescaled vs NetworkX (1e-12)"] += 1
    spec = "U: " + ", ".join(f"{u}-{v}" for u in range(3) for v in range(3, 6))
    row(G_, "K3,3, the left column as given, the right in vertices order", f"`{spec}`", "bipartiteLayout(left: [5, 3, 4])", pts(bipartite(6, [5, 3, 4])))
    row(G_, "rescaled: NetworkX bipartite_layout", f"`{spec}`", "bipartiteLayout(left: [3, 4, 5]).rescaled()", pts(rescaled(got)))
    row(G_, "a column of one vertex at y = -1/2, aspect ratio 2", "`U: n=3; 0-1`", "bipartiteLayout(left: [1], aspectRatio: 2)", pts(bipartite(3, [1], 2.0)))
    row(G_, "a left vertex listed twice", "`U: n=3;`", "bipartiteLayout(left: [0, 0])", "**trap**")
    G_ = "Multipartite"
    row(G_, "layers sorted, gaps make no empty column, vertices order within a column", "`U: n=6;` layers [7, -3, 7, 100, 7, -3]",
        "multipartiteLayout(layer: { [7, -3, 7, 100, 7, -3][$0] })", pts(columns([7, -3, 7, 100, 7, -3], [1, 5, 0, 2, 4, 3])))
    G_ = "BFS"
    g = parse("U: n=4; 0-3, 0-2, 0-2, 2-2, 1-2")
    row(G_, "discovery order within a column", "`U: n=4; 0-3, 0-2, 0-2, 2-2, 1-2`", "bfsLayout(start: 0)",
        pts(columns(bfs_hops(g, 0), bfs_order(g, 0))))
    row(G_, "a vertex not reachable from the start", "`U: n=3; 0-1`", "bfsLayout(start: 0)", "**trap**")
    G_ = "Random"
    got, draws = initial_random(5, 7)
    row(G_, "x then y per vertex, the top 53 bits of each draw", "`U: n=5; 0-1`", "randomLayout(using: &Xoshiro256StarStar(seed: 7))", pts(got))
    G_ = "Scaling"
    for spec, length, label in [("U: C(0,1,2)", [3.0, 4.0, 5.0], "a 3-4-5 triangle by edge length"),
                                ("U: lcggraph(12,20,9)", None, "random graph, 12 vertices, 20 edges"),
                                ("U: n=3; 0-1, 1-0", [2.0, 4.0], "an isolated vertex 1 + 3 sqrt 3 from both ends")]:
        g = parse(spec)
        got, w, D = scaling(g, length)
        if g.n >= 3 and nx.is_connected(g.simple_nx()) and w[-1] - w[-2] > 1e-6 and w[-2] - w[-3] > 1e-6:
            theirs = np.array(ig.Graph(n=g.n, edges=[e for e in g.edges if e[0] != e[1]]).layout_mds(dist=D.tolist(), dim=2).coords)
            ours = np.array(got)
            gap = np.abs(np.linalg.norm(ours[:, None] - ours[None], axis=-1) - np.linalg.norm(theirs[:, None] - theirs[None], axis=-1)).max()
            assert gap <= 1e-9, gap
            CHECKS["scaling vs igraph layout_mds (distances, 1e-9)"] += 1
        op = "multidimensionalScalingLayout()" if length is None else f"multidimensionalScalingLayout(edgeLength: {{ {[int(x) for x in length]}[$0] }})"
        row(G_, label, f"`{spec}`", op, pts(got, 9))
    row(G_, "a zero edge length", "`U: P(0,1,2)`", "multidimensionalScalingLayout(edgeLength: { _ in 0 })", "**trap**")
    G_ = "Planar"
    for spec, label in [("U: K(4)", "K4"), ("U: grid(4,5)", "grid 4 x 5"), ("U: petersen", "Petersen")]:
        g = parse(spec)
        planar, _ = nx.check_planarity(g.simple_nx())
        CHECKS["planarity vs NetworkX check_planarity"] += 1
        if planar:
            row(G_, f"{label}: integer points in [0, 2n - 4] x [0, n - 2], no crossing", f"`{spec}`", "planarLayout()", "#0 crossings")
        else:
            row(G_, f"{label}: not planar", f"`{spec}`", "planarLayout()", "nil")
    for spec, label in [("U: K(5)", "K5"), ("U: " + ", ".join(f"{u}-{v}" for u in range(3) for v in range(3, 6)), "K3,3")]:
        assert not nx.check_planarity(parse(spec).simple_nx())[0]
        row(G_, f"{label}: not planar", f"`{spec}`", "planarLayout()", "nil")
    row(G_, "two triangles and an isolated vertex, loops and parallel edges", "`U: n=7; C(0,1,2), C(3,4,5), 0-1, 4-4`", "planarLayout()", "#0 crossings")
    row(G_, "fewer than four vertices: (0, 0), (2, 0), (1, 1)", "`U: P(0,1,2)`", "planarLayout()", pts([(0, 0), (2, 0), (1, 1)]))


# ============================================================================ stress

def stress():
    c = defaultdict(int)
    rnd = Xoshiro256StarStar(2026)
    for t in range(300):
        n = 1 + (rnd.next() % 60)
        st = lcg_stream(1000 + t)
        par = [None] + [next(st) % i for i in range(1, n)]
        pos = reingold_tilford(par)
        assert not tree_invariants(par, pos), t
        par2, new = mirrored(par)
        pos2 = reingold_tilford(par2)
        assert close([pos2[new[v]] for v in range(n)], [(-x, y) for x, y in pos], 1e-9), t
        c["trees mirror-symmetric"] += 1
        edges = [(par[v], v) for v in range(n) if par[v] is not None]
        if n > 1:
            ip = [tuple(p) for p in ig.Graph(n=n, edges=edges).layout_reingold_tilford(root=[0], mode="all").coords]
            if not tree_invariants(par, ip):
                c["igraph trees with every parent centred"] += 1
            if close(pos, ip, 1e-9):
                c["trees equal to igraph"] += 1
            else:
                c["trees differing from igraph"] += 1
        c["trees"] += 1
    for t in range(200):
        n = 2 + (rnd.next() % 14)
        m = rnd.next() % (2 * n)
        kind = "lcgdag" if t % 2 else "lcggraph"
        g = parse(f"D: n={n}; {kind}({n},{m},{5000 + t})") if m else parse(f"D: n={n};")
        res = sugiyama(g.n, g.edges)
        c["digraphs"] += 1
        if res["layer"] is not None:
            assert not sugiyama_invariants(g.n, g.edges, res), t
            c["digraphs with a unique optimal layering (positions checked)"] += 1
        if not res["reversed"]:
            a, b = igraph_span(g), res_span(g, res)
            assert a >= b, t
            c["acyclic: igraph span optimal" if a == b else "acyclic: igraph span above optimum"] += 1
        else:
            c["cyclic: total span equal to igraph" if igraph_span(g) == res_span(g, res) else "cyclic: total span differing from igraph"] += 1
    for t in range(40):
        n = 3 + (rnd.next() % 20)
        g = parse(f"U: n={n}; lcggraph({n},{n + rnd.next() % n},{9000 + t})")
        if not nx.is_connected(g.simple_nx()):
            continue
        P, s, _ = stress_majorization(g)
        kk = nx.kamada_kawai_layout(g.simple_nx())
        a, b = normalized_stress(g, P), normalized_stress(g, [kk[i] for i in range(n)])
        c["stress runs"] += 1
        c["stress <= 1.02 x KK + 1e-4" if a <= 1.02 * b + 1e-4 else "stress > 1.02 x KK + 1e-4"] += 1
    return c


# ============================================================================ bench

def bench():
    import subprocess
    jobs = [
        ("networkx spring_layout (force), random 3-regular", "nx_spring", 1000),
        ("networkx spring_layout (force), random 3-regular", "nx_spring", 10000),
        ("networkx kamada_kawai_layout, random 3-regular", "nx_kk", 500),
        ("igraph layout_fruchterman_reingold, random 3-regular", "ig_fr", 1000),
        ("igraph layout_fruchterman_reingold, random 3-regular", "ig_fr", 10000),
        ("igraph layout_fruchterman_reingold grid, random 3-regular", "ig_fr_grid", 100000),
        ("igraph layout_drl, random 3-regular", "ig_drl", 100000),
        ("igraph layout_kamada_kawai, random 3-regular", "ig_kk", 1000),
        ("igraph layout_reingold_tilford, random tree", "ig_rt", 1000000),
        ("igraph layout_sugiyama, random DAG m = 2n", "ig_sug", 1000),
        ("igraph layout_sugiyama, random DAG m = 2n", "ig_sug", 10000),
        ("networkx circular_layout", "nx_circ", 1000000),
    ]
    for label, job, n in jobs:
        try:
            out = subprocess.run([sys.executable, __file__, "--bench-one", job, str(n)], capture_output=True,
                                 text=True, timeout=120).stdout.strip()
        except subprocess.TimeoutExpired:
            out = "> 120 s"
        print(f"| {label} | {n:,} | {out} |")


def bench_one(job, n):
    if job.startswith("nx_") or job.startswith("ig_"):
        gn = nx.random_regular_graph(3, n, seed=1) if job not in ("ig_rt", "ig_sug", "nx_circ") else None
    t0 = time.perf_counter()
    if job == "nx_spring":
        nx.spring_layout(gn, seed=1, method="force")
    elif job == "nx_kk":
        nx.kamada_kawai_layout(gn)
    elif job == "nx_circ":
        nx.circular_layout(nx.empty_graph(n))
    else:
        if gn is not None:
            gi = ig.Graph(n=n, edges=list(gn.edges()))
            t0 = time.perf_counter()
        if job == "ig_fr":
            gi.layout_fruchterman_reingold(grid="nogrid")
        elif job == "ig_fr_grid":
            gi.layout_fruchterman_reingold(grid="grid")
        elif job == "ig_drl":
            gi.layout_drl()
        elif job == "ig_kk":
            gi.layout_kamada_kawai()
        elif job == "ig_rt":
            st = lcg_stream(1)
            gi = ig.Graph(n=n, edges=[(next(st) % i, i) for i in range(1, n)])
            t0 = time.perf_counter()
            gi.layout_reingold_tilford(root=[0])
        elif job == "ig_sug":
            st = lcg_stream(1)
            es = []
            while len(es) < 2 * n:
                a, b = next(st) % n, next(st) % n
                if a != b:
                    es.append((min(a, b), max(a, b)))
            gi = ig.Graph(n=n, edges=es, directed=True)
            t0 = time.perf_counter()
            gi.layout_sugiyama()
    print(f"{(time.perf_counter() - t0) * 1000:.1f} ms")


# ============================================================================ output

HEADER = """# GraphDrawing: case catalog (DR-001 – DR-{last:03d}, {count} rows)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
igraph==1.0.0 --with numpy==2.3.4 --with scipy==1.18.1 python3 Tests/Catalogs/GraphDrawing/ref.py`;
`--write` regenerates this file, `--stress` adds random trees, digraphs and graphs, `--bench` prints
baseline timings). Coordinates only: every expected value is a list of points, a layer, a
count or a bound. The model implements every layout from the definitions in api.md. Circular
positions and `rescaled` are compared with NetworkX 3.7; tree layouts with python-igraph 1.0.0's
`layout_reingold_tilford` and `layout_reingold_tilford_circular`; Sugiyama layers with igraph's
`layout_sugiyama`; stress majorization with NetworkX's `kamada_kawai_layout`; the spectral rows
with NetworkX's `spectral_layout` up to the sign of each axis; shell, spiral, bipartite,
multipartite and BFS positions with NetworkX's layouts; classical scaling with igraph's `layout_mds`
up to a rigid motion; planarity of the planar rows with NetworkX's `check_planarity`. api.md lists
where the tools differ.

## Notation

**Input.** `U:` undirected, `D:` directed; `n=N;` lists vertices 0..<N first; then edges in
**position order**. Vertices are the `Int`s 0..<n, `vertices` in that order. `T:` is a
`RootedTree<Int>` built with `RootedTree(parents:)`, so `children(of:)` lists children by
ascending vertex.

| Token | Edges |
|---|---|
| `u-v`, `u>v` | one edge; one arc |
| `P(a,b,…)`, `C(a,…,z)` | the path a–b, b–c, …; the cycle, closing z–a (arcs in a `D:` graph) |
| `K(n)` | every pair i < j, lexicographic |
| `grid(r,c)` | vertex `i*c + j`; for each vertex in order the edge right, then down |
| `Q(d)` | hypercube: for i in order, for k = 0..<d, i–(i ^ 2^k) when i < i ^ 2^k |
| `petersen` | 0–1, 1–2, 2–3, 3–4, 4–0, then i–(i+5) for i = 0…4, then (5+i)–(5+(i+2) mod 5) |
| `lcggraph(n,m,s)` | m edges (u, v), u ≠ v, from the LCG below: draw u = x mod n, v = x′ mod n, skip u = v (parallel edges possible) |
| `lcgdag(n,m,s)` | as `lcggraph`, each arc oriented min → max |
| `T: [p0, p1, …]` | `parents`, `nil` for the root |
| `T: bal(b,h)` | the complete b-ary tree of height h, parent of v is (v − 1) / b |
| `T: lcgtree(n,s)` | parent of i (1 ≤ i < n) is x mod i, one LCG draw per i |

The LCG: x ← x · 6364136223846793005 + 1442695040888963407 (mod 2⁶⁴), seeded with s, each draw
is x >> 33 after the step.

**Expected.** Points are `(x, y)`; `[…]` lists them in `vertices` order. Values printed with up to
12 decimals involve `cos`/`sin` (circular layouts): compare with tolerance 1e-9. Every other point
list is exact (multiples of 1/2ⁿ from separation-1 arithmetic). `≤ v` rows are quality bounds on a
median over seeds 1…20 of `Xoshiro256StarStar(seed:)` (normalized stress or crossing count, as
defined in api.md, computed in the test from `positions`); `≈ v (±1%)` rows are a converged value.
`#N` is a count. `**trap**` rows are preconditions. The spectral and scaling rows print 9 decimals
(compare within 1e-8); `#0 crossings` rows count crossings, shared points and vertices on edges of
the straight-line drawing in the test, and check the grid bounds.

"""


def number_rows():
    for i, r in enumerate(ROWS):
        r[0] = f"DR-{i + 1:03d}"


def render():
    lines = [HEADER.format(last=len(ROWS), count=len(ROWS)).rstrip("\n"), ""]
    lines.append("| ID | Group | Case | Input | Op | Expected |")
    lines.append("|---|---|---|---|---|---|")
    for r in ROWS:
        cells = [r[0], r[1], r[2], r[3] if r[3].startswith("`") else f"`{r[3]}`", f"`{r[4]}`", r[5]]
        lines.append("| " + " | ".join(c.replace("|", "\\|") for c in cells) + " |")
    lines.append("")
    lines.append(f"{len(ROWS)} rows.")
    return "\n".join(lines) + "\n"


def main():
    if "--bench-one" in sys.argv:
        i = sys.argv.index("--bench-one")
        bench_one(sys.argv[i + 1], int(sys.argv[i + 2]))
        return
    if "--bench" in sys.argv:
        bench()
        return
    drawing_rows()
    circular_rows()
    tree_rows()
    sugiyama_rows()
    fr_rows()
    stress_rows()
    more_rows()
    layout_rows()
    number_rows()
    text = render()
    path = os.path.join(HERE, "cases.md")
    if "--write" in sys.argv:
        open(path, "w").write(text)
        print(f"wrote {len(ROWS)} rows")
    else:
        if not os.path.exists(path) or open(path).read() != text:
            print("cases.md differs from the model (run with --write)")
            sys.exit(1)
        print(f"cases.md matches the model: {len(ROWS)} rows")
    for k, v in sorted(CHECKS.items()):
        print(f"  checked: {k}: {v}")
    for (lib, why), k in sorted(DISAGREE.items()):
        print(f"  known disagreement, {k} rows: {lib}: {why}")
    if "--stress" in sys.argv:
        c = stress()
        print("stress: " + ", ".join(f"{k} {v}" for k, v in sorted(c.items())))


if __name__ == "__main__":
    main()
