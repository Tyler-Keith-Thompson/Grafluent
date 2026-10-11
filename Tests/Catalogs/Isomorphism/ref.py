#!/usr/bin/env python3
"""Reference model for IsomorphismModule (Tests/Catalogs/Isomorphism).

Run: uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with rustworkx==0.18.1 \
         python3 Tests/Catalogs/Isomorphism/ref.py [--write] [--stress] [--bench] [--export DIR]

The model works in index space, from the definitions in api.md:

  * a mapping f from the pattern G to the target H is an isomorphism when it is a bijection and,
    for every ordered pair (u, v) of pattern vertices (u == v included), the multiset of edge
    colours between u and v equals the one between f(u) and f(v); a subgraph isomorphism when it
    is an injection with the same equality (induced); a monomorphism when it is an injection and
    each pattern multiset is contained in the target's. Without edge colours the multiset is the
    edge multiplicity, so parallel edges and self-loops count. Vertex colours must be equal.
  * `match` enumerates mappings by backtracking (pattern vertices in a connectivity order,
    candidates filtered by colour, degree and, for isomorphism, the joint 1-WL colour). Below 8
    target vertices every row is also checked against brute force over all injections.
  * Weisfeiler–Leman: colour refinement from the vertex colours (uniform without them); one round
    replaces a colour by (colour, sorted multiset of (edge colour, neighbour colour) over the edge
    ends), and on a directed graph by (colour, out-multiset, in-multiset). Partitions after each
    round, and hash equality as equality of the colour histograms after every round.
  * Automorphism groups (phase 2): the order and orbits from enumeration, or from python-igraph's
    bliss (`count_automorphisms`, `automorphism_group`) when the group is large; generators are
    checked to generate a group of that order.

Every row is cross-checked against NetworkX 3.7 (GraphMatcher family and vf2pp), python-igraph
1.0.0 (VF2, LAD, bliss) and rustworkx 0.18.1 (vf2_mapping), each where it supports the input; the
known disagreements are listed in KNOWN and in api.md. --write regenerates cases.md; without it the
run fails if cases.md differs. --stress adds random graphs checked against brute force and the
three libraries. --bench prints the baseline timings api.md quotes. --export DIR writes each bench
pair's edge lists (DIR/<case>.g.deflate, DIR/<case>.h.deflate: raw deflate of the vertex count, then one edge per
line), the
inputs IsomorphismBenchmarks reads, so both sides time the same graphs.
"""
import itertools
import zlib
import math
import os
import random
import re
import subprocess
import sys
import time
import warnings
from collections import Counter

warnings.simplefilter("ignore")

import igraph as ig  # noqa: E402
import networkx as nx  # noqa: E402
import rustworkx as rx  # noqa: E402
from networkx.algorithms import isomorphism as nxiso  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
MASK = (1 << 64) - 1


class Trap(Exception):
    pass


# ============================================================================ graphs

class G:
    """A graph in index space: vertex names in `vertices` order, edges (u, v) by index in position
    order (an undirected edge is listed once, a self-loop as (u, u))."""

    def __init__(self, directed, vertices, edges):
        self.directed = directed
        self.vertices = list(vertices)
        self.n = len(self.vertices)
        self.edges = list(edges)
        self.m = len(self.edges)

    def is_simple(self):
        seen = set()
        for u, v in self.edges:
            if u == v:
                return False
            k = (u, v) if self.directed else (min(u, v), max(u, v))
            if k in seen:
                return False
            seen.add(k)
        return True

    def has_loops(self):
        return any(u == v for u, v in self.edges)

    def pair_colors(self, ecolor=None):
        """{(u, v): sorted tuple of edge colours}; both orders for an undirected edge."""
        pc = {}
        for p, (u, v) in enumerate(self.edges):
            c = ecolor[p] if ecolor is not None else 0
            pc.setdefault((u, v), []).append(c)
            if not self.directed and u != v:
                pc.setdefault((v, u), []).append(c)
        return {k: tuple(sorted(x)) for k, x in pc.items()}

    def degree(self):
        """Edge ends at each vertex (a loop counts 2); directed: (out, in)."""
        if self.directed:
            out, inn = [0] * self.n, [0] * self.n
            for u, v in self.edges:
                out[u] += 1
                inn[v] += 1
            return list(zip(out, inn))
        d = [0] * self.n
        for u, v in self.edges:
            d[u] += 1
            d[v] += 1
        return d

    def ends(self, ecolor=None):
        """Per vertex, (edge colour, other end) over the edge ends: out and in lists when directed."""
        col = (lambda p: ecolor[p]) if ecolor is not None else (lambda p: 0)
        if self.directed:
            out, inn = [[] for _ in range(self.n)], [[] for _ in range(self.n)]
            for p, (u, v) in enumerate(self.edges):
                out[u].append((col(p), v))
                inn[v].append((col(p), u))
            return out, inn
        nb = [[] for _ in range(self.n)]
        for p, (u, v) in enumerate(self.edges):
            nb[u].append((col(p), v))
            nb[v].append((col(p), u))   # a loop: both ends at u
        return nb, None


def items(s):
    s = s.strip()
    if not s:
        return []
    out = []
    for t in s.split(","):
        t = t.strip()
        m = re.fullmatch(r"(-?\d+)\.\.(-?\d+)", t)
        if m:
            out += list(range(int(m.group(1)), int(m.group(2)) + 1))
        else:
            out.append(int(t) if re.fullmatch(r"-?\d+", t) else t)
    return out


def split_top(s):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth -= 1
        if ch == "," and depth == 0:
            if cur.strip():
                out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def lcg_edges(n, m, seed):
    """m pseudo-random non-loop pairs over 0..<n (the Distances catalog's LCG)."""
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


def is_square_mod(x, q):
    return any((y * y - x) % q == 0 for y in range(1, q))


def gen_edges(t):
    """(listed vertices, [(a, b)]) for one generator token."""
    if t.startswith("P("):
        vs = items(t[2:-1])
        return [], list(zip(vs, vs[1:]))
    if t.startswith("C("):
        vs = items(t[2:-1])
        return [], list(zip(vs, vs[1:] + vs[:1]))
    if t.startswith("S("):
        c, rest = t[2:-1].split(";")
        return [], [(int(c), x) for x in items(rest)]
    if t.startswith("KB("):
        a, b = t[3:-1].split(";")
        return [], [(x, y) for x in items(a) for y in items(b)]
    if t.startswith("K("):
        vs = items(t[2:-1]) if ".." in t else list(range(int(t[2:-1])))
        return vs, [(vs[i], vs[j]) for i in range(len(vs)) for j in range(i + 1, len(vs))]
    if t.startswith("E("):                       # E(n): n isolated vertices 0..n-1
        return list(range(int(t[2:-1]))), []
    if t.startswith("grid("):
        r, c = map(int, t[5:-1].split(","))
        es = []
        for i in range(r):
            for j in range(c):
                v = i * c + j
                if j + 1 < c:
                    es.append((v, v + 1))
                if i + 1 < r:
                    es.append((v, v + c))
        return list(range(r * c)), es
    if t.startswith("Q("):                       # hypercube: i ~ i ^ (1 << k), i < j, by i then k
        d = int(t[2:-1])
        return list(range(1 << d)), [(i, i ^ (1 << k)) for i in range(1 << d) for k in range(d) if i < i ^ (1 << k)]
    if t.startswith("paley("):                   # i < j adjacent iff j - i is a nonzero square mod q
        q = int(t[6:-1])
        return list(range(q)), [(i, j) for i in range(q) for j in range(i + 1, q) if is_square_mod(j - i, q)]
    if t.startswith("tpaley("):                  # tournament: i > j iff j - i is a square mod q
        q = int(t[7:-1])
        return list(range(q)), [(i, j) for i in range(q) for j in range(q) if i != j and is_square_mod((j - i) % q, q)]
    if t.startswith("tt("):                      # transitive tournament: i > j for i < j
        k = int(t[3:-1])
        return list(range(k)), [(i, j) for i in range(k) for j in range(i + 1, k)]
    if t.startswith("rook("):                    # K_k □ K_k: (i, j) = i*k + j; same row or column
        k = int(t[5:-1])
        vs = list(range(k * k))
        return vs, [(a, b) for a in vs for b in vs if a < b and (a // k == b // k or a % k == b % k)]
    if t == "shrikhande":                        # Cayley graph of Z4 x Z4, {±(1,0), ±(0,1), ±(1,1)}
        gen = [(1, 0), (3, 0), (0, 1), (0, 3), (1, 1), (3, 3)]
        es = []
        for a in range(16):
            for b in range(a + 1, 16):
                d = ((b // 4 - a // 4) % 4, (b % 4 - a % 4) % 4)
                if d in gen:
                    es.append((a, b))
        return list(range(16)), es
    if t.startswith("nx("):
        g = getattr(nx, t[3:-1] + "_graph")()
        return list(g.nodes), list(g.edges())
    if t.startswith("lcg("):
        n, m, s = map(int, t[4:-1].split(","))
        return list(range(n)), lcg_edges(n, m, s)
    if t.startswith("cfi(") or t.startswith("cfi~("):
        base = parse_graph("U: " + t[t.index("(") + 1:-1])
        vs, es = cfi(base, twisted=t.startswith("cfi~"))
        return vs, es
    m = re.fullmatch(r"(-?\w+)([->=])(-?\w+)", t)
    assert m, f"bad token {t!r}"
    a, b = items(m.group(1))[0], items(m.group(3))[0]
    if m.group(2) == "=":                        # a=b: two parallel copies
        return [], [(a, b), (a, b)]
    return [], [(a, b)]


def cfi(base, twisted):
    """Cai–Fürer–Immerman graph over `base` (api.md, notation). Per base vertex v in index order:
    the middle vertices, one per even subset S of v's incidences (bitmask ascending), then for each
    incidence j in position order a(v, j, 0), a(v, j, 1). Edges: per v, per S ascending, per j:
    S – a(v, j, [j ∈ S]); then per base edge e = (u, w) in position order, for i = 0, 1:
    a(u, j_u, i) – a(w, j_w, i XOR t), t = 1 only for the first edge of the twisted graph."""
    inc = [[] for _ in range(base.n)]
    for p, (u, w) in enumerate(base.edges):
        inc[u].append(p)
        inc[w].append(p)
    num, mids, a = 0, {}, {}
    for v in range(base.n):
        d = len(inc[v])
        for s in range(1 << d):
            if bin(s).count("1") % 2 == 0:
                mids[(v, s)] = num
                num += 1
        for j in range(d):
            for i in (0, 1):
                a[(v, j, i)] = num
                num += 1
    es = []
    for v in range(base.n):
        d = len(inc[v])
        for s in range(1 << d):
            if (v, s) in mids:
                for j in range(d):
                    es.append((mids[(v, s)], a[(v, j, (s >> j) & 1)]))
    for p, (u, w) in enumerate(base.edges):
        ju, jw = inc[u].index(p), inc[w].index(p)
        t = 1 if (twisted and p == 0) else 0
        for i in (0, 1):
            es.append((a[(u, ju, i)], a[(w, jw, i ^ t)]))
    return list(range(num)), es


def parse_graph(cell):
    cell = cell.strip().strip("`")
    remap = None
    m = re.search(r"\s*~map\((\d+),(\d+)\)$", cell)
    if m:
        remap = (int(m.group(1)), int(m.group(2)))
        cell = cell[: m.start()]
    kind, rest = cell.split(":", 1)
    m = re.match(r"\s*\[(.*?)\]\s*(.*)", rest)
    listed, es = (m.group(1), m.group(2)) if m else ("", rest)
    extra, pairs = [], []
    for t in split_top(es):
        a, b = gen_edges(t)
        extra += a
        pairs += b
    vs, seen = [], set()
    for v in items(listed) + extra + [x for p in pairs for x in p]:
        if v not in seen:
            seen.add(v)
            vs.append(v)
    if remap:
        a, b = remap
        n = len(vs)
        assert sorted(vs) == list(range(n)) and math.gcd(a, n) == 1, cell
        pairs = [((a * x + b) % n, (a * y + b) % n) for x, y in pairs]
        vs = list(range(n))
    num = {v: i for i, v in enumerate(vs)}
    return G(kind.strip() == "D", vs, [(num[x], num[y]) for x, y in pairs])


# ============================================================================ the model

def wl_rounds(g, k, vcolor=None, ecolor=None, intern=None):
    """Colour refinement: the colours after rounds 0..k. A colour is an integer naming its
    signature in `intern`; pass one dictionary for two graphs and equal integers mean equal
    signatures (the canonical colours, without nesting)."""
    intern = {} if intern is None else intern

    def name(sig):
        return intern.setdefault(sig, len(intern))

    cur = [name(("v", vcolor[i]) if vcolor is not None else ("v",)) for i in range(g.n)]
    out_ends, in_ends = g.ends(ecolor)
    hist = [cur]
    for _ in range(k):
        if g.directed:
            cur = [name((cur[v], tuple(sorted((c, cur[w]) for c, w in out_ends[v])),
                         tuple(sorted((c, cur[w]) for c, w in in_ends[v])))) for v in range(g.n)]
        else:
            cur = [name((cur[v], tuple(sorted((c, cur[w]) for c, w in out_ends[v])))) for v in range(g.n)]
        hist.append(cur)
    return hist


def partition(colors, names):
    classes = {}
    for i, c in enumerate(colors):
        classes.setdefault(c, []).append(names[i])
    return sorted(classes.values(), key=lambda c: names.index(c[0]))


def joint_stable_colors(g, h, vcg, vch, ecg, ech):
    """The stable joint refinement of g and h, as integers comparable across the two graphs:
    rounds until neither partition gets finer."""
    intern = {}
    rg, rh = wl_rounds(g, 0, vcg, ecg, intern), wl_rounds(h, 0, vch, ech, intern)
    cg, ch = rg[0], rh[0]
    while True:
        ng = wl_rounds_step(g, cg, ecg, intern)
        nh = wl_rounds_step(h, ch, ech, intern)
        if len(set(ng)) == len(set(cg)) and len(set(nh)) == len(set(ch)):
            return cg, ch
        cg, ch = ng, nh


def wl_rounds_step(g, cur, ecolor, intern):
    out_ends, in_ends = g.ends(ecolor)

    def name(sig):
        return intern.setdefault(sig, len(intern))
    if g.directed:
        return [name((cur[v], tuple(sorted((c, cur[w]) for c, w in out_ends[v])),
                      tuple(sorted((c, cur[w]) for c, w in in_ends[v])))) for v in range(g.n)]
    return [name((cur[v], tuple(sorted((c, cur[w]) for c, w in out_ends[v])))) for v in range(g.n)]


def connectivity_order(g, cand_size):
    """Pattern order: repeatedly the vertex with most already-ordered neighbours, then fewest
    candidates, then highest degree, then least index."""
    nb = [set() for _ in range(g.n)]
    for u, v in g.edges:
        nb[u].add(v)
        nb[v].add(u)
    deg = [len(x) for x in nb]
    order, placed = [], set()
    while len(order) < g.n:
        best = min((v for v in range(g.n) if v not in placed),
                   key=lambda v: (-len(nb[v] & placed), cand_size[v], -deg[v], v))
        order.append(best)
        placed.add(best)
    return order


def match(g, h, mode, vcg=None, vch=None, ecg=None, ech=None):
    """Every mapping g -> h (a list of target indices per pattern index), for mode in
    'iso', 'induced', 'mono', in backtracking order."""
    if mode == "iso" and (g.n != h.n or g.m != h.m):
        return []
    if g.n > h.n:
        return []
    pg, ph = g.pair_colors(ecg), h.pair_colors(ech)
    dg, dh = g.degree(), h.degree()
    if mode == "iso":
        cg, ch = joint_stable_colors(g, h, vcg, vch, ecg, ech)
        if Counter(cg) != Counter(ch):
            return []
        cands = [[x for x in range(h.n) if ch[x] == cg[u]] for u in range(g.n)]
    else:
        def fits(du, dx):
            if g.directed:
                return du[0] <= dx[0] and du[1] <= dx[1]
            return du <= dx
        cands = [[x for x in range(h.n)
                  if (vcg is None or vcg[u] == vch[x]) and fits(dg[u], dh[x])] for u in range(g.n)]
    order = connectivity_order(g, [len(c) for c in cands])

    def ok(a, b):
        if mode == "mono":
            return not (Counter(a) - Counter(b))
        return a == b

    f, used, out = [None] * g.n, set(), []

    def rec(i):
        if i == g.n:
            out.append(f[:])
            return
        u = order[i]
        for x in cands[u]:
            if x in used:
                continue
            good = ok(pg.get((u, u), ()), ph.get((x, x), ()))
            j = 0
            while good and j < i:
                w = order[j]
                y = f[w]
                good = ok(pg.get((u, w), ()), ph.get((x, y), ())) and ok(pg.get((w, u), ()), ph.get((y, x), ()))
                j += 1
            if good:
                f[u] = x
                used.add(x)
                rec(i + 1)
                used.discard(x)
                f[u] = None

    rec(0)
    return out


def is_valid(g, h, mode, f, vcg=None, vch=None, ecg=None, ech=None):
    """The definition, checked directly on one mapping."""
    if len(f) != g.n or len(set(f)) != len(f) or any(not (0 <= x < h.n) for x in f):
        return False
    if mode == "iso" and g.n != h.n:
        return False
    if vcg is not None and any(vcg[u] != vch[f[u]] for u in range(g.n)):
        return False
    pg, ph = g.pair_colors(ecg), h.pair_colors(ech)
    for u in range(g.n):
        for v in range(g.n):
            a, b = Counter(pg.get((u, v), ())), Counter(ph.get((f[u], f[v]), ()))
            if mode == "mono":
                if a - b:
                    return False
            elif a != b:
                return False
    return True


def brute(g, h, mode, vcg=None, vch=None, ecg=None, ech=None):
    if mode == "iso" and g.n != h.n:
        return []
    return sorted(list(p) for p in itertools.permutations(range(h.n), g.n)
                  if is_valid(g, h, mode, list(p), vcg, vch, ecg, ech))


# ============================================================================ libraries

def to_nx(g, vc=None, ec=None):
    multi = not g.is_simple() and any(c > 1 for c in Counter(
        (u, v) if g.directed else (min(u, v), max(u, v)) for u, v in g.edges).values())
    cls = {(False, False): nx.Graph, (True, False): nx.DiGraph,
           (False, True): nx.MultiGraph, (True, True): nx.MultiDiGraph}[(g.directed, multi)]
    x = cls()
    for i in range(g.n):
        x.add_node(i, c=vc[i] if vc is not None else 0)
    for p, (u, v) in enumerate(g.edges):
        x.add_edge(u, v, c=ec[p] if ec is not None else 0)
    return x, multi


def to_ig(g):
    return ig.Graph(g.n, g.edges, directed=g.directed)


def to_rx(g, vc=None, ec=None):
    x = rx.PyDiGraph() if g.directed else rx.PyGraph()
    x.add_nodes_from([vc[i] if vc is not None else 0 for i in range(g.n)])
    for p, (u, v) in enumerate(g.edges):
        x.add_edge(u, v, ec[p] if ec is not None else 0)
    return x


def colour_ints(cs):
    if cs is None:
        return None
    ids = {}
    return [ids.setdefault(c, len(ids)) for c in cs]


def library_mappings(g, h, mode, vcg, vch, ecg, ech):
    """{library: set of mappings (tuples, pattern index -> target index)} for every library that
    supports the input. NetworkX's subgraph matchers take (target, pattern) and map target ->
    pattern; they are inverted here."""
    res = {}
    gx, gm = to_nx(g, vcg, ecg)
    hx, hm = to_nx(h, vch, ech)
    multi = gm or hm
    nm = nxiso.categorical_node_match("c", None)
    em = (nxiso.categorical_multiedge_match("c", None) if multi else nxiso.categorical_edge_match("c", None))
    if gm != hm:   # NetworkX needs both graphs of one class: promote the simple one
        gx, hx = (nx.MultiDiGraph(gx) if g.directed else nx.MultiGraph(gx)), (nx.MultiDiGraph(hx) if h.directed else nx.MultiGraph(hx))
    Matcher = {(False, False): nxiso.GraphMatcher, (True, False): nxiso.DiGraphMatcher,
               (False, True): nxiso.MultiGraphMatcher, (True, True): nxiso.MultiDiGraphMatcher}[(g.directed, multi)]

    def inv(d):
        r = [None] * g.n
        for t, p in d.items():
            r[p] = t
        return tuple(r)

    if mode == "iso":
        res["networkx GraphMatcher"] = {tuple(d[i] for i in range(g.n)) for d in Matcher(gx, hx, nm, em).isomorphisms_iter()}
    elif mode == "induced":
        res["networkx GraphMatcher"] = {inv(d) for d in Matcher(hx, gx, nm, em).subgraph_isomorphisms_iter()}
    else:
        res["networkx GraphMatcher"] = {inv(d) for d in Matcher(hx, gx, nm, em).subgraph_monomorphisms_iter()}
    if ecg is None:   # vf2pp: vertex labels only
        lab = "c" if vcg is not None else None
        if mode == "iso":
            it = nx.vf2pp_all_isomorphisms(gx, hx, node_label=lab)
            res["networkx vf2pp"] = {tuple(d[i] for i in range(g.n)) for d in it}
        elif mode == "induced":
            res["networkx vf2pp"] = {inv(d) for d in nx.vf2pp_all_subgraph_isomorphisms(hx, gx, node_label=lab)}
        else:
            res["networkx vf2pp"] = {inv(d) for d in nxiso.vf2pp_all_monomorphisms(hx, gx, node_label=lab)}
    loopless = not g.has_loops() and not h.has_loops()
    if loopless or not multi:   # igraph VF2 rejects self-loops, LAD rejects parallel edges
        gi, hi = to_ig(g), to_ig(h)
        kw = {}
        if vcg is not None:
            ids = {}
            kw["color1"] = [ids.setdefault(c, len(ids)) for c in vcg]
            kw["color2"] = [ids.setdefault(c, len(ids)) for c in vch]
        if ecg is not None:
            ids = {}
            kw["edge_color1"] = [ids.setdefault(c, len(ids)) for c in ecg]
            kw["edge_color2"] = [ids.setdefault(c, len(ids)) for c in ech]
        if mode == "iso" and loopless:
            # each list maps the other graph's vertices to this one's: inverted here
            res["igraph VF2"] = {tuple(sorted(range(len(m)), key=lambda j: m[j])) for m in gi.get_isomorphisms_vf2(hi, **kw)}
        elif mode == "mono" and loopless:
            # igraph's subisomorphic_vf2 is a monomorphism test (api.md, disagreements); color1
            # and edge_color1 belong to the graph the method is called on, the target
            sw = {}
            for a, b in (("color1", "color2"), ("edge_color1", "edge_color2")):
                if a in kw:
                    sw[a], sw[b] = kw[b], kw[a]
            res["igraph VF2"] = {tuple(m) for m in hi.get_subisomorphisms_vf2(gi, **sw)}
        if vcg is None and ecg is None and mode != "iso" and g.n > 0 and not multi:
            res["igraph LAD"] = {tuple(m) for m in hi.get_subisomorphisms_lad(gi, induced=(mode == "induced"))}
    if not (multi and ecg is not None):
        gr, hr = to_rx(g, vcg, ecg), to_rx(h, vch, ech)
        kw = dict(node_matcher=(lambda a, b: a == b), edge_matcher=(lambda a, b: a == b))
        if mode == "iso":
            maps = rx.vf2_mapping(gr, hr, **kw)
            res["rustworkx"] = {tuple(m[i] for i in range(g.n)) for m in maps}
        else:
            maps = rx.vf2_mapping(hr, gr, subgraph=True, induced=(mode == "induced"), **kw)
            res["rustworkx"] = {inv(dict(m)) for m in maps}
    return res


# Library answers that differ from the definition, by (library, reason). Each is in api.md.
def known(lib, g, h, mode, ours, theirs, ecg):
    if lib == "networkx vf2pp" and (g.n == 0 or h.n == 0) and not theirs:
        return "vf2pp returns no mapping when a graph is empty"
    if lib == "igraph VF2" and not (g.is_simple() and h.is_simple()):
        return "VF2 on parallel edges" + (" with edge colours" if ecg is not None else "")
    if lib == "igraph LAD" and (g.has_loops() or h.has_loops()):
        return "LAD with self-loops"
    return None


DISAGREE = Counter()


def cross_check(g, h, mode, maps, vcg, vch, ecg, ech, where):
    ours = {tuple(f) for f in maps}
    for lib, theirs in library_mappings(g, h, mode, vcg, vch, ecg, ech).items():
        if theirs == ours:
            continue
        why = known(lib, g, h, mode, ours, theirs, ecg)
        assert why, f"{where}: {lib} gives {len(theirs)} mappings, the model {len(ours)}"
        DISAGREE[(lib, why)] += 1


# ============================================================================ the catalog

ROWS = []


def fmt_map(g, h, f):
    return "[" + ", ".join(str(h.vertices[x]) for x in f) + "]"


def fmt_part(p):
    return " ".join("{" + ",".join(map(str, c)) + "}" for c in p)


def parse_colors(op):
    """`... vertexColor: G [..] H [..]` and `edgeColor: G [..] H [..]` (H absent on one graph)."""
    def grab(key):
        m = re.search(key + r": G \[(.*?)\](?: H \[(.*?)\])?", op)
        if not m:
            return None, None
        a = items(m.group(1))
        b = items(m.group(2)) if m.group(2) is not None else None
        return a, b
    vcg, vch = grab("vertexColor")
    ecg, ech = grab("edgeColor")
    return vcg, vch, ecg, ech


MODES = {"isomorphism": "iso", "isomorphisms": "iso", "isIsomorphic": "iso",
         "subgraphIsomorphism": "induced", "subgraphIsomorphisms": "induced", "isSubgraphIsomorphic": "induced",
         "monomorphism": "mono", "monomorphisms": "mono", "isMonomorphic": "mono"}


def automorphisms_info(g, vc=None, ec=None):
    """(order, orbits as index lists) by enumeration when small, else from bliss."""
    if g.is_simple() and ec is None:
        gi = to_ig(g)
        kw = {"color": colour_ints(vc)} if vc is not None else {}
        order = gi.count_automorphisms(**kw)
        gens = gi.automorphism_group(**kw)
        # orbits of the generated group
        parent = list(range(g.n))

        def find(x):
            while parent[x] != x:
                parent[x] = parent[parent[x]]
                x = parent[x]
            return x
        for p in gens:
            for i, j in enumerate(p):
                parent[find(i)] = find(j)
        orbits = {}
        for i in range(g.n):
            orbits.setdefault(find(i), []).append(i)
        orb = sorted(orbits.values())
        if order <= 20000:   # the generators generate a group of exactly that order
            assert group_closure_size([tuple(p) for p in gens], g.n, 20000) == order
            maps = match(g, g, "iso", vc, vc, ec, ec)
            assert len(maps) == order
            assert orbits_from(maps, g.n) == orb
        return order, orb
    maps = match(g, g, "iso", vc, vc, ec, ec)
    return len(maps), orbits_from(maps, g.n)


def orbits_from(maps, n):
    seen, out = set(), []
    for v in range(n):
        if v in seen:
            continue
        o = sorted({f[v] for f in maps})
        seen |= set(o)
        out.append(o)
    return out


def group_closure_size(gens, n, cap):
    ident = tuple(range(n))
    seen, frontier = {ident}, [ident]
    while frontier and len(seen) <= cap:
        nxt = []
        for p in frontier:
            for s in gens:
                q = tuple(s[p[i]] for i in range(n))
                if q not in seen:
                    seen.add(q)
                    nxt.append(q)
        frontier = nxt
    return len(seen)


def evaluate(gcell, hcell, op):
    g = parse_graph(gcell)
    h = parse_graph(hcell) if hcell else None
    vcg, vch, ecg, ech = parse_colors(op)
    m = re.match(r"(\w+)", op)
    name = m.group(1)
    if name in MODES:
        mode = MODES[name]
        maps = match(g, h, mode, vcg, vch, ecg, ech)
        for f in maps:
            assert is_valid(g, h, mode, f, vcg, vch, ecg, ech)
        assert len({tuple(f) for f in maps}) == len(maps)
        if h.n <= 7:
            assert sorted(maps) == brute(g, h, mode, vcg, vch, ecg, ech), (gcell, hcell, op)
        if len(maps) <= 6000:
            cross_check(g, h, mode, maps, vcg, vch, ecg, ech, f"{gcell} | {hcell} | {op}")
        if name.startswith("is") and name[2].isupper():
            return "true" if maps else "false"
        if ".count" in op:
            return f"#{len(maps)}"
        if name.endswith("s"):   # the whole sequence, as a set
            return "{" + ", ".join(fmt_map(g, h, f) for f in sorted(maps)) + "}"
        if not maps:
            return "nil"
        if len(maps) == 1:
            return fmt_map(g, h, maps[0])
        return f"some (one of #{len(maps)})"
    if name == "weisfeilerLehmanGraphHash":
        k = int(re.search(r"iterations: (-?\d+)", op).group(1))
        if k < 0:
            return "**trap** (iterations must be at least 0)"
        intern = {}
        rg, rh = wl_rounds(g, k, vcg, ecg, intern), wl_rounds(h, k, vch, ech, intern)
        eq = all(Counter(a) == Counter(b) for a, b in zip(rg, rh))
        # NetworkX agrees on equality on simple graphs without colours from iterations 2 on. At
        # iterations 1 without attributes it hashes an empty history, so every graph is equal
        # (api.md, disagreements).
        if k == 1 and vcg is None and ecg is None and g.is_simple() and h.is_simple():
            a = nx.weisfeiler_lehman_graph_hash(to_nx(g)[0], iterations=1)
            assert a == nx.weisfeiler_lehman_graph_hash(to_nx(h)[0], iterations=1)
            if not eq:
                DISAGREE[("networkx weisfeiler_lehman_graph_hash", "iterations=1 without attributes hashes nothing")] += 1
        if k >= 2 and g.is_simple() and h.is_simple() and vcg is None and ecg is None:
            a = nx.weisfeiler_lehman_graph_hash(to_nx(g)[0], iterations=k)
            b = nx.weisfeiler_lehman_graph_hash(to_nx(h)[0], iterations=k)
            assert (a == b) == eq, (gcell, hcell, op)
        if eq and g.n == h.n:   # an isomorphism must give equal hashes; check the converse direction
            pass
        if match(g, h, "iso", vcg, vch, ecg, ech):
            assert eq
        return "equal" if eq else "different"
    if name == "weisfeilerLehmanSubgraphHashes":
        k = int(re.search(r"iterations: (-?\d+)", op).group(1))
        if k < 0:
            return "**trap** (iterations must be at least 0)"
        rounds = wl_rounds(g, k, vcg, ecg)
        parts = [partition(r, g.vertices) for r in rounds[1:]]
        if g.is_simple() and vcg is None and ecg is None and k >= 1:
            hs = nx.weisfeiler_lehman_subgraph_hashes(to_nx(g)[0], iterations=k)
            for i in range(k):
                assert partition([hs[v][i] for v in range(g.n)], g.vertices) == parts[i], (gcell, op, i)
        return "; ".join(f"r{i + 1}: {fmt_part(p)}" for i, p in enumerate(parts)) if parts else "(no rounds)"
    if name == "automorphismGroup":
        order, orbits = automorphisms_info(g, vcg, ecg)
        if "().order" in op:
            return str(order)
        if not orbits:
            return "(none)"
        return fmt_part([[g.vertices[i] for i in o] for o in orbits])
    if name == "image" or name == "preimage":
        # `image(of: v) after isomorphism(to:)` etc.: the first mapping the model finds
        mm = re.match(r"(image|preimage)\(of: (-?\w+)\) after (\w+)", op)
        mode = MODES[mm.group(3)]
        maps = match(g, h, mode, vcg, vch, ecg, ech)
        assert len(maps) == 1, "trap and nil rows use a unique mapping"
        f = maps[0]
        v = items(mm.group(2))[0]
        if mm.group(1) == "image":
            if v not in g.vertices:
                return f"**trap** ({v} is not a vertex of the pattern)"
            return str(h.vertices[f[g.vertices.index(v)]])
        if v not in h.vertices:
            return f"**trap** ({v} is not a vertex of the target)"
        x = h.vertices.index(v)
        return str(g.vertices[f.index(x)]) if x in f else "nil"
    raise AssertionError(f"unknown op {op}")


def R(group, case, g, h, op):
    ROWS.append([None, group, case, g, h or "", op])


def define():
    # ------------------------------------------------------------ A. isomorphism, undirected
    A = "Isomorphism"
    R(A, "empty graphs: the empty mapping", "U:", "U:", "isIsomorphic(to:)")
    R(A, "empty graphs: one mapping, the empty one", "U:", "U:", "isomorphisms(to:)")
    R(A, "empty graphs: isomorphism(to:) is the empty mapping", "U:", "U:", "isomorphism(to:)")
    R(A, "one vertex each", "U: [0]", "U: [7]", "isomorphism(to:)")
    R(A, "different vertex counts", "U: [0]", "U: [0, 1]", "isIsomorphic(to:)")
    R(A, "same vertex count, different edge counts", "U: P(0,1,2)", "U: [0, 1, 2] 0-1", "isIsomorphic(to:)")
    R(A, "path against star, same counts, degrees differ", "U: P(0,1,2,3)", "U: S(0;1..3)", "isIsomorphic(to:)")
    R(A, "C6 against two triangles: same degrees, 1-WL equal", "U: C(0,1,2,3,4,5)", "U: C(0,1,2), C(3,4,5)", "isIsomorphic(to:)")
    R(A, "C6 against two triangles: no mapping", "U: C(0,1,2,3,4,5)", "U: C(0,1,2), C(3,4,5)", "isomorphism(to:)")
    R(A, "C6 against a relabelled C6", "U: C(0,1,2,3,4,5)", "U: C(0,1,2,3,4,5) ~map(5,2)", "isomorphisms(to:).count")
    R(A, "C4: all eight", "U: C(0,1,2,3)", "U: C(0,1,2,3)", "isomorphisms(to:)")
    R(A, "P3 onto a relabelled P3: both", "U: P(0,1,2)", "U: P(1,0,2)", "isomorphisms(to:)")
    R(A, "path P5", "U: P(0,1,2,3,4)", "U: P(0,1,2,3,4) ~map(2,1)", "isomorphisms(to:).count")
    R(A, "K4", "U: K(4)", "U: K(4)", "isomorphisms(to:).count")
    R(A, "K5", "U: K(5)", "U: K(5) ~map(2,3)", "isomorphisms(to:).count")
    R(A, "K3,3", "U: KB(0..2;3..5)", "U: KB(0..2;3..5) ~map(5,1)", "isomorphisms(to:).count")
    R(A, "star K1,5", "U: S(0;1..5)", "U: S(5;0..4)", "isomorphisms(to:).count")
    R(A, "five isolated vertices", "U: E(5)", "U: E(5)", "isomorphisms(to:).count")
    R(A, "grid 3x3", "U: grid(3,3)", "U: grid(3,3) ~map(2,0)", "isomorphisms(to:).count")
    R(A, "cube Q3", "U: Q(3)", "U: Q(3) ~map(3,1)", "isomorphisms(to:).count")
    R(A, "hypercube Q4", "U: Q(4)", "U: Q(4) ~map(5,3)", "isomorphisms(to:).count")
    R(A, "Petersen", "U: nx(petersen)", "U: nx(petersen) ~map(3,4)", "isomorphisms(to:).count")
    R(A, "Petersen: some mapping", "U: nx(petersen)", "U: nx(petersen) ~map(3,4)", "isomorphism(to:)")
    R(A, "Heawood", "U: nx(heawood)", "U: nx(heawood) ~map(3,5)", "isomorphisms(to:).count")
    R(A, "Möbius–Kantor", "U: nx(moebius_kantor)", "U: nx(moebius_kantor) ~map(5,7)", "isomorphisms(to:).count")
    R(A, "Desargues against the dodecahedron: both cubic on 20 vertices", "U: nx(desargues)", "U: nx(dodecahedral)", "isIsomorphic(to:)")
    R(A, "dodecahedron", "U: nx(dodecahedral)", "U: nx(dodecahedral) ~map(3,7)", "isomorphisms(to:).count")
    R(A, "Paley(13)", "U: paley(13)", "U: paley(13) ~map(2,5)", "isomorphisms(to:).count")
    R(A, "Shrikhande against the 4x4 rook's graph: both srg(16,6,2,2)", "U: shrikhande", "U: rook(4)", "isIsomorphic(to:)")
    R(A, "Shrikhande", "U: shrikhande", "U: shrikhande ~map(3,1)", "isomorphisms(to:).count")
    R(A, "4x4 rook's graph", "U: rook(4)", "U: rook(4) ~map(5,2)", "isomorphisms(to:).count")
    R(A, "Frucht (asymmetric): the one mapping", "U: nx(frucht)", "U: nx(frucht) ~map(5,1)", "isomorphism(to:)")
    R(A, "Frucht onto itself: only the identity", "U: nx(frucht)", "U: nx(frucht)", "isomorphisms(to:)")
    R(A, "asymmetric tree on 7 vertices: the one mapping", "U: P(0,1,2,3,4,5), 2-6", "U: P(6,5,4,3,2,1), 4-0", "isomorphism(to:)")
    R(A, "two trees with one degree sequence", "U: P(0,1,2,3,4), 1-5", "U: P(0,1,2,3,4), 2-5", "isIsomorphic(to:)")
    R(A, "karate club against a relabelling", "U: nx(karate_club)", "U: nx(karate_club) ~map(5,3)", "isomorphisms(to:).count")
    R(A, "isolated vertex kept: K2 + K1", "U: [0, 1, 2] 0-1", "U: [0, 1, 2] 2-1", "isomorphisms(to:)")
    R(A, "disconnected: 2K2 against P3 + K1", "U: 0-1, 2-3", "U: [0, 1, 2, 3] 0-1, 1-2", "isIsomorphic(to:)")
    R(A, "disconnected: 2C3 + K1 against a relabelling", "U: [6] C(0,1,2), C(3,4,5)", "U: [0] C(1,2,3), C(4,5,6)", "isomorphisms(to:).count")
    R(A, "vertex names: images are target vertices, in pattern `vertices` order", "U: [5, 9, 7] 5-9", "U: [2, 0, 4] 4-2", "isomorphism(to:) vertexColor: G [a,b,c] H [a,c,b]")
    R(A, "CFI over K4 against its twisted copy: 1-WL equal, not isomorphic", "U: cfi(K(4))", "U: cfi~(K(4))", "isIsomorphic(to:)")
    R(A, "CFI over K4 against a relabelling", "U: cfi(K(4))", "U: cfi(K(4)) ~map(7,3)", "isomorphisms(to:).count")
    R(A, "random graph lcg(12,24,1) against a relabelling", "U: lcg(12,24,1)", "U: lcg(12,24,1) ~map(5,7)", "isomorphisms(to:).count")
    R(A, "lcg(12,24,1) against lcg(12,24,2)", "U: lcg(12,24,1)", "U: lcg(12,24,2)", "isIsomorphic(to:)")

    # ------------------------------------------------------------ B. self-loops and parallel edges
    B = "Loops and parallel edges"
    R(B, "loop at the end of an edge, either end", "U: 0-0, 0-1", "U: 1-1, 0-1", "isomorphism(to:)")
    R(B, "a loop counts 2: degrees (2,1,1) both, still not isomorphic", "U: 0-0, 1-2", "U: P(0,1,2)", "isIsomorphic(to:)")
    R(B, "loop against no loop", "U: [0] 0-0", "U: [0]", "isIsomorphic(to:)")
    R(B, "two loops against one", "U: 0-0, 0-0", "U: 0-0, 1-1", "isIsomorphic(to:)")
    R(B, "two loops on one vertex against two loops on one vertex", "U: 0-0, 0-0, 0-1", "U: 0-1, 1-1, 1-1", "isomorphism(to:)")
    R(B, "parallel pair moves to the other edge", "U: 0=1, 1-2", "U: 0-1, 1=2", "isomorphism(to:)")
    R(B, "parallel pair against a path: same degrees", "U: 0=1, 2-3", "U: P(0,1,2,3)", "isIsomorphic(to:)")
    R(B, "multiplicity 3 against 2 + 1 elsewhere", "U: 0=1, 0-1", "U: 0=1, 1-2", "isIsomorphic(to:)")
    R(B, "doubled triangle", "U: 0=1, 1=2, 2=0", "U: 0=1, 1=2, 2=0", "isomorphisms(to:).count")
    R(B, "doubled C4", "U: 0=1, 1=2, 2=3, 3=0", "U: 0=1, 1=2, 2=3, 3=0", "isomorphisms(to:).count")
    R(B, "bouquet: one vertex, three loops", "U: 0-0, 0-0, 0-0", "U: 0-0, 0-0, 0-0", "isomorphisms(to:)")
    R(B, "loops and parallel edges together", "U: 0-0, 0=1, 1-2, 2-2", "U: 2-2, 2=1, 1-0, 0-0", "isomorphisms(to:)")

    # ------------------------------------------------------------ C. directed
    D = "Directed"
    R(D, "out-path against in-star: same counts", "D: 0>1, 1>2", "D: 0>1, 2>1", "isIsomorphic(to:)")
    R(D, "directed C3 against itself", "D: C(0,1,2)", "D: C(0,1,2)", "isomorphisms(to:)")
    R(D, "directed C3 against its reverse", "D: C(0,1,2)", "D: C(2,1,0)", "isomorphisms(to:)")
    R(D, "directed C3 against the transitive tournament", "D: C(0,1,2)", "D: tt(3)", "isIsomorphic(to:)")
    R(D, "transitive tournament on 5: only one", "D: tt(5)", "D: tt(5) ~map(2,1)", "isomorphism(to:)")
    R(D, "Paley tournament on 7", "D: tpaley(7)", "D: tpaley(7) ~map(3,2)", "isomorphisms(to:).count")
    R(D, "2-cycle against two parallel arcs", "D: 0>1, 1>0", "D: 0>1, 0>1", "isIsomorphic(to:)")
    R(D, "2-cycle against itself", "D: 0>1, 1>0", "D: 0>1, 1>0", "isomorphisms(to:)")
    R(D, "same out-degrees, in-degrees differ", "D: 0>1, 0>2, 1>2", "D: 0>1, 0>2, 2>0", "isIsomorphic(to:)")
    R(D, "loop at the tail against loop at the head", "D: 0>0, 0>1", "D: 1>1, 0>1", "isomorphism(to:)")
    R(D, "directed loop moves across the arc", "D: 0>0, 0>1", "D: 1>1, 1>0", "isomorphism(to:)")
    R(D, "orientations of C4: alternating against cyclic", "D: 0>1, 2>1, 2>3, 0>3", "D: C(0,1,2,3)", "isIsomorphic(to:)")
    R(D, "random digraph lcg(10,25,3) against a relabelling", "D: lcg(10,25,3)", "D: lcg(10,25,3) ~map(3,4)", "isomorphisms(to:).count")
    R(D, "directed multigraph: three parallel arcs", "D: 0>1, 0>1, 0>1", "D: 1>0, 1>0, 1>0", "isomorphism(to:)")

    # ------------------------------------------------------------ D. colours
    V = "Colours"
    R(V, "C4, colours r r b b against r b r b", "U: C(0,1,2,3)", "U: C(0,1,2,3)", "isIsomorphic(to:) vertexColor: G [r,r,b,b] H [r,b,r,b]")
    R(V, "C4, colours r r b b against b r r b", "U: C(0,1,2,3)", "U: C(0,1,2,3)", "isomorphisms(to:) vertexColor: G [r,r,b,b] H [b,r,r,b]")
    R(V, "colour class sizes differ", "U: C(0,1,2,3)", "U: C(0,1,2,3)", "isIsomorphic(to:) vertexColor: G [r,r,r,b] H [r,r,b,b]")
    R(V, "a colour missing from the target", "U: K(3)", "U: K(3)", "isIsomorphic(to:) vertexColor: G [r,r,g] H [r,r,b]")
    R(V, "Petersen with one vertex coloured: its stabiliser", "U: nx(petersen)", "U: nx(petersen)", "isomorphisms(to:).count vertexColor: G [x,o,o,o,o,o,o,o,o,o] H [x,o,o,o,o,o,o,o,o,o]")
    R(V, "Petersen, the coloured vertex elsewhere", "U: nx(petersen)", "U: nx(petersen)", "isomorphisms(to:).count vertexColor: G [x,o,o,o,o,o,o,o,o,o] H [o,o,o,o,o,o,o,x,o,o]")
    R(V, "uniform colours change nothing", "U: nx(petersen)", "U: nx(petersen) ~map(3,4)", "isomorphisms(to:).count vertexColor: G [0,0,0,0,0,0,0,0,0,0] H [0,0,0,0,0,0,0,0,0,0]")
    R(V, "distinct colours: at most one mapping", "U: K(4)", "U: K(4)", "isomorphisms(to:) vertexColor: G [a,b,c,d] H [d,c,b,a]")
    R(V, "edge colours on C4: a a b b against a b a b", "U: C(0,1,2,3)", "U: C(0,1,2,3)", "isIsomorphic(to:) edgeColor: G [a,a,b,b] H [a,b,a,b]")
    R(V, "edge colours on C4: a a b b against b a a b", "U: C(0,1,2,3)", "U: C(0,1,2,3)", "isomorphisms(to:) edgeColor: G [a,a,b,b] H [b,a,a,b]")
    R(V, "edge colours on a triangle: one of each", "U: C(0,1,2)", "U: C(0,1,2)", "isomorphisms(to:) edgeColor: G [a,b,c] H [c,a,b]")
    R(V, "parallel pair: colours {a, b} against {a, a}", "U: 0=1", "U: 0=1", "isIsomorphic(to:) edgeColor: G [a,b] H [a,a]")
    R(V, "parallel pair: colours {a, b} against {b, a}", "U: 0=1", "U: 0=1", "isomorphisms(to:) edgeColor: G [a,b] H [b,a]")
    R(V, "loop colours", "U: 0-0, 0-1, 1-1", "U: 0-0, 0-1, 1-1", "isomorphisms(to:) edgeColor: G [a,c,b] H [b,c,a]")
    R(V, "vertex and edge colours together", "U: P(0,1,2)", "U: P(0,1,2)", "isomorphisms(to:) vertexColor: G [r,b,r] H [r,b,r] edgeColor: G [x,y] H [y,x]")
    R(V, "directed: arc colours", "D: C(0,1,2)", "D: C(0,1,2)", "isomorphisms(to:) edgeColor: G [a,a,b] H [a,b,a]")

    # ------------------------------------------------------------ E. subgraph isomorphism (induced)
    S = "Subgraph isomorphism (induced)"
    R(S, "P3 in K3: every image has the third edge", "U: P(0,1,2)", "U: K(3)", "isSubgraphIsomorphic(to:)")
    R(S, "K2 in P4: each edge, both ways", "U: P(0,1)", "U: P(0,1,2,3)", "subgraphIsomorphisms(to:)")
    R(S, "two isolated vertices in P4: non-adjacent pairs", "U: E(2)", "U: P(0,1,2,3)", "subgraphIsomorphisms(to:)")
    R(S, "C4 in K4: never induced", "U: C(0,1,2,3)", "U: K(4)", "subgraphIsomorphisms(to:).count")
    R(S, "2K2 in P4: the middle edge is in the way", "U: 0-1, 2-3", "U: P(0,1,2,3)", "subgraphIsomorphisms(to:).count")
    R(S, "K3 in Petersen (girth 5)", "U: K(3)", "U: nx(petersen)", "isSubgraphIsomorphic(to:)")
    R(S, "C5 in Petersen: 12 five-cycles, 10 ways each", "U: C(0,1,2,3,4)", "U: nx(petersen)", "subgraphIsomorphisms(to:).count")
    R(S, "P3 in Petersen", "U: P(0,1,2)", "U: nx(petersen)", "subgraphIsomorphisms(to:).count")
    R(S, "C6 in Petersen", "U: C(0,1,2,3,4,5)", "U: nx(petersen)", "subgraphIsomorphisms(to:).count")
    R(S, "K4 in K6", "U: K(4)", "U: K(6)", "subgraphIsomorphisms(to:).count")
    R(S, "C4 in Q3: the six faces", "U: C(0,1,2,3)", "U: Q(3)", "subgraphIsomorphisms(to:).count")
    R(S, "P4 in grid 3x3", "U: P(0,1,2,3)", "U: grid(3,3)", "subgraphIsomorphisms(to:).count")
    R(S, "claw K1,3 in grid 4x4", "U: S(0;1..3)", "U: grid(4,4)", "subgraphIsomorphisms(to:).count")
    R(S, "pattern larger than target", "U: K(3)", "U: K(2)", "isSubgraphIsomorphic(to:)")
    R(S, "empty pattern: the empty mapping", "U:", "U: P(0,1,2)", "subgraphIsomorphisms(to:)")
    R(S, "empty pattern, empty target", "U:", "U:", "subgraphIsomorphisms(to:).count")
    R(S, "a whole graph is its own induced subgraph", "U: nx(petersen)", "U: nx(petersen)", "subgraphIsomorphisms(to:).count")
    R(S, "K1 into a vertex with a loop: the loop is induced", "U: [0]", "U: 0-0, 0-1", "subgraphIsomorphisms(to:)")
    R(S, "loop pattern into a loop target", "U: 0-0", "U: 0-0, 0-1", "subgraphIsomorphisms(to:)")
    R(S, "K2 into a parallel pair: multiplicity must be equal", "U: 0-1", "U: 0=1", "isSubgraphIsomorphic(to:)")
    R(S, "parallel pair into a parallel pair", "U: 0=1", "U: 0=1, 1-2", "subgraphIsomorphisms(to:)")
    R(S, "directed: arc into a 2-cycle", "D: 0>1", "D: 0>1, 1>0", "isSubgraphIsomorphic(to:)")
    R(S, "directed: out-path in directed C3", "D: 0>1, 1>2", "D: C(0,1,2)", "isSubgraphIsomorphic(to:)")
    R(S, "directed: out-path in directed C4", "D: 0>1, 1>2", "D: C(0,1,2,3)", "subgraphIsomorphisms(to:).count")
    R(S, "directed: arc in the transitive tournament on 4", "D: 0>1", "D: tt(4)", "subgraphIsomorphisms(to:).count")
    R(S, "coloured: red–blue edges in a coloured path", "U: P(0,1)", "U: P(0,1,2,3)", "subgraphIsomorphisms(to:) vertexColor: G [r,b] H [r,b,b,r]")
    R(S, "coloured edges: an a-edge in C4", "U: P(0,1)", "U: C(0,1,2,3)", "subgraphIsomorphisms(to:) edgeColor: G [a] H [a,b,a,b]")
    R(S, "subgraphIsomorphism(to:): the unique one", "U: P(0,1,2)", "U: [9] P(5,6,7), 9-5", "subgraphIsomorphism(to:) vertexColor: G [x,y,z] H [x,y,z,w]")
    R(S, "subgraphIsomorphism(to:): none", "U: K(3)", "U: nx(petersen)", "subgraphIsomorphism(to:)")
    R(S, "random target lcg(14,30,5): P4", "U: P(0,1,2,3)", "U: lcg(14,30,5)", "subgraphIsomorphisms(to:).count")

    # ------------------------------------------------------------ F. monomorphism (non-induced)
    M = "Monomorphism (non-induced)"
    R(M, "P3 in K3", "U: P(0,1,2)", "U: K(3)", "monomorphisms(to:)")
    R(M, "two isolated vertices in P4: every ordered pair", "U: E(2)", "U: P(0,1,2,3)", "monomorphisms(to:).count")
    R(M, "C4 in K4: three 4-cycles, 8 ways each", "U: C(0,1,2,3)", "U: K(4)", "monomorphisms(to:).count")
    R(M, "2K2 in P4", "U: 0-1, 2-3", "U: P(0,1,2,3)", "monomorphisms(to:)")
    R(M, "C5 in Petersen: same as induced (girth 5)", "U: C(0,1,2,3,4)", "U: nx(petersen)", "monomorphisms(to:).count")
    R(M, "C4 in K3,3", "U: C(0,1,2,3)", "U: KB(0..2;3..5)", "monomorphisms(to:).count")
    R(M, "Hamiltonian cycles: C8 in Q3", "U: C(0,1,2,3,4,5,6,7)", "U: Q(3)", "monomorphisms(to:).count")
    R(M, "Hamiltonian paths: P10 in Petersen", "U: P(0,1,2,3,4,5,6,7,8,9)", "U: nx(petersen)", "monomorphisms(to:).count")
    R(M, "spanning: C10 in Petersen (not Hamiltonian)", "U: C(0,1,2,3,4,5,6,7,8,9)", "U: nx(petersen)", "isMonomorphic(to:)")
    R(M, "perfect matchings: 3K2 in K3,3", "U: 0-1, 2-3, 4-5", "U: KB(0..2;3..5)", "monomorphisms(to:).count")
    R(M, "K4 in K6", "U: K(4)", "U: K(6)", "monomorphisms(to:).count")
    R(M, "K4 in grid", "U: K(4)", "U: grid(3,3)", "isMonomorphic(to:)")
    R(M, "empty pattern", "U:", "U: K(3)", "monomorphisms(to:)")
    R(M, "pattern larger than target", "U: E(3)", "U: K(2)", "isMonomorphic(to:)")
    R(M, "K1 into a loop vertex: allowed", "U: [0]", "U: [0] 0-0", "monomorphisms(to:)")
    R(M, "loop pattern into a vertex without a loop", "U: 0-0", "U: 0-1", "isMonomorphic(to:)")
    R(M, "K2 into a parallel pair: one copy is enough", "U: 0-1", "U: 0=1", "monomorphisms(to:)")
    R(M, "parallel pair into a single edge", "U: 0=1", "U: 0-1", "isMonomorphic(to:)")
    R(M, "triple edge into a double edge", "U: 0=1, 0-1", "U: 0=1", "isMonomorphic(to:)")
    R(M, "double edge into a triple edge", "U: 0=1", "U: 0=1, 0-1", "monomorphisms(to:)")
    R(M, "directed: arc into a 2-cycle", "D: 0>1", "D: 0>1, 1>0", "monomorphisms(to:)")
    R(M, "directed: out-path in directed C3", "D: 0>1, 1>2", "D: C(0,1,2)", "monomorphisms(to:)")
    R(M, "directed: 2-cycle into the transitive tournament", "D: 0>1, 1>0", "D: tt(4)", "isMonomorphic(to:)")
    R(M, "directed: directed triangles in tpaley(7)", "D: C(0,1,2)", "D: tpaley(7)", "monomorphisms(to:).count")
    R(M, "coloured edges: multiset containment", "U: 0=1", "U: 0=1, 0-1", "monomorphisms(to:) edgeColor: G [a,b] H [a,a,b]")
    R(M, "coloured edges: a colour missing", "U: 0=1", "U: 0=1, 0-1", "isMonomorphic(to:) edgeColor: G [a,b] H [a,a,c]")
    R(M, "coloured vertices", "U: P(0,1)", "U: K(3)", "monomorphisms(to:) vertexColor: G [r,r] H [r,b,r]")
    R(M, "monomorphism(to:): none", "U: C(0,1,2,3)", "U: nx(petersen)", "monomorphism(to:)")
    R(M, "monomorphism(to:): the unique one", "U: P(0,1,2)", "U: K(3)", "monomorphism(to:) vertexColor: G [a,b,c] H [c,a,b]")
    R(M, "random target lcg(14,30,5): C4", "U: C(0,1,2,3)", "U: lcg(14,30,5)", "monomorphisms(to:).count")

    # ------------------------------------------------------------ G. Weisfeiler–Leman
    W = "Weisfeiler–Leman"
    R(W, "C6 against 2C3: never distinguished", "U: C(0,1,2,3,4,5)", "U: C(0,1,2), C(3,4,5)", "weisfeilerLehmanGraphHash(iterations: 3)")
    R(W, "Shrikhande against rook(4): never distinguished", "U: shrikhande", "U: rook(4)", "weisfeilerLehmanGraphHash(iterations: 3)")
    R(W, "CFI against twisted CFI: never distinguished", "U: cfi(K(4))", "U: cfi~(K(4))", "weisfeilerLehmanGraphHash(iterations: 5)")
    R(W, "isomorphic graphs: equal", "U: nx(petersen)", "U: nx(petersen) ~map(3,4)", "weisfeilerLehmanGraphHash(iterations: 3)")
    R(W, "P4 against the star: degrees differ in round 1", "U: P(0,1,2,3)", "U: S(0;1..3)", "weisfeilerLehmanGraphHash(iterations: 1)")
    R(W, "zero rounds: only the vertex count", "U: P(0,1,2,3)", "U: S(0;1..3)", "weisfeilerLehmanGraphHash(iterations: 0)")
    R(W, "zero rounds, different vertex counts", "U: E(3)", "U: E(4)", "weisfeilerLehmanGraphHash(iterations: 0)")
    R(W, "two trees, one degree sequence: equal after 1 round", "U: P(0,1,2,3,4), 1-5", "U: P(0,1,2,3,4), 2-5", "weisfeilerLehmanGraphHash(iterations: 1)")
    R(W, "two trees, one degree sequence: different after 2", "U: P(0,1,2,3,4), 1-5", "U: P(0,1,2,3,4), 2-5", "weisfeilerLehmanGraphHash(iterations: 2)")
    R(W, "decalin against bicyclopentyl (NetworkX docstring)", "U: P(0,1,2,3,4,5,6,7,8,9), 0-5, 4-9", "U: C(0,1,2,3,4), C(5,6,7,8,9), 0-5", "weisfeilerLehmanGraphHash(iterations: 3)")
    R(W, "decalin against bicyclopentyl with element colours", "U: P(0,1,2,3,4,5,6,7,8,9), 0-5, 4-9", "U: C(0,1,2,3,4), C(5,6,7,8,9), 0-5", "weisfeilerLehmanGraphHash(iterations: 3) edgeColor: G [s,s,s,s,s,s,s,s,s,d,s] H [s,s,s,s,s,s,s,s,s,s,d]")
    R(W, "vertex colours separate C4 colourings", "U: C(0,1,2,3)", "U: C(0,1,2,3)", "weisfeilerLehmanGraphHash(iterations: 2) vertexColor: G [r,r,b,b] H [r,b,r,b]")
    R(W, "edge colours separate C4 colourings", "U: C(0,1,2,3)", "U: C(0,1,2,3)", "weisfeilerLehmanGraphHash(iterations: 2) edgeColor: G [a,a,b,b] H [a,b,a,b]")
    R(W, "parallel pair against P4: degrees equal, neighbours not", "U: 0=1, 2-3", "U: P(0,1,2,3)", "weisfeilerLehmanGraphHash(iterations: 2)")
    R(W, "a loop counts as two edge ends", "U: 0-0, 1-2", "U: P(0,1,2)", "weisfeilerLehmanGraphHash(iterations: 1)")
    R(W, "a loop: degrees equal, neighbours not", "U: 0-0, 1-2", "U: P(0,1,2)", "weisfeilerLehmanGraphHash(iterations: 2)")
    R(W, "directed: out-path against in-star", "D: 0>1, 1>2", "D: 0>1, 2>1", "weisfeilerLehmanGraphHash(iterations: 1)")
    R(W, "directed: C3 against its reverse", "D: C(0,1,2)", "D: C(2,1,0)", "weisfeilerLehmanGraphHash(iterations: 3)")
    R(W, "negative iterations", "U: K(2)", "U: K(2)", "weisfeilerLehmanGraphHash(iterations: -1)")
    R(W, "P5 partitions", "U: P(0,1,2,3,4)", None, "weisfeilerLehmanSubgraphHashes(iterations: 3)")
    R(W, "tree partitions", "U: P(0,1,2,3,4), 1-5", None, "weisfeilerLehmanSubgraphHashes(iterations: 3)")
    R(W, "Petersen: one class from round 1 on", "U: nx(petersen)", None, "weisfeilerLehmanSubgraphHashes(iterations: 2)")
    R(W, "Frucht: refinement stops short of the orbits", "U: nx(frucht)", None, "weisfeilerLehmanSubgraphHashes(iterations: 4)")
    R(W, "karate club, three rounds", "U: nx(karate_club)", None, "weisfeilerLehmanSubgraphHashes(iterations: 3)")
    R(W, "vertex colours start the refinement", "U: P(0,1,2,3,4)", None, "weisfeilerLehmanSubgraphHashes(iterations: 2) vertexColor: G [a,b,a,a,a]")
    R(W, "edge colours", "U: C(0,1,2,3)", None, "weisfeilerLehmanSubgraphHashes(iterations: 2) edgeColor: G [a,a,b,b]")
    R(W, "directed: in- and out-neighbours both count", "D: 0>1, 2>1, 1>3", None, "weisfeilerLehmanSubgraphHashes(iterations: 2)")
    R(W, "loops and parallel edges", "U: 0-0, 0-1, 1=2, 2-3", None, "weisfeilerLehmanSubgraphHashes(iterations: 2)")
    R(W, "zero rounds: no hashes", "U: P(0,1,2)", None, "weisfeilerLehmanSubgraphHashes(iterations: 0)")
    R(W, "negative iterations", "U: P(0,1,2)", None, "weisfeilerLehmanSubgraphHashes(iterations: -1)")

    # ------------------------------------------------------------ H. mapping accessors
    X = "Isomorphism value"
    R(X, "image(of:) a pattern vertex", "U: [5, 9, 7] 5-9", "U: [2, 0, 4] 4-2", "image(of: 7) after isomorphism(to:) vertexColor: G [a,b,c] H [a,c,b]")
    R(X, "image(of:) a vertex not in the pattern", "U: [5, 9, 7] 5-9", "U: [2, 0, 4] 4-2", "image(of: 3) after isomorphism(to:) vertexColor: G [a,b,c] H [a,c,b]")
    R(X, "preimage(of:) a target vertex", "U: [5, 9, 7] 5-9", "U: [2, 0, 4] 4-2", "preimage(of: 2) after isomorphism(to:) vertexColor: G [a,b,c] H [a,c,b]")
    R(X, "preimage(of:) a target vertex outside the image", "U: P(0,1,2)", "U: [9] P(5,6,7), 9-5", "preimage(of: 7) after subgraphIsomorphism(to:) vertexColor: G [x,y,z] H [x,y,z,w]")
    R(X, "preimage(of:) a vertex not in the target", "U: P(0,1,2)", "U: [9] P(5,6,7), 9-5", "preimage(of: 3) after subgraphIsomorphism(to:) vertexColor: G [x,y,z] H [x,y,z,w]")

    # ------------------------------------------------------------ I. automorphism group (phase 2)
    Z = "Phase 2: automorphismGroup"
    for name, cell in [("empty graph", "U:"), ("K1", "U: [0]"), ("P5", "U: P(0,1,2,3,4)"),
                       ("K2,3", "U: KB(0..1;2..4)"), ("K3,3", "U: KB(0..2;3..5)"),
                       ("Petersen", "U: nx(petersen)"), ("Frucht", "U: nx(frucht)"),
                       ("Heawood", "U: nx(heawood)"), ("Q3", "U: Q(3)"), ("Q5", "U: Q(5)"),
                       ("Shrikhande", "U: shrikhande"), ("rook(4)", "U: rook(4)"), ("Paley(13)", "U: paley(13)"),
                       ("Paley(29)", "U: paley(29)"), ("karate club", "U: nx(karate_club)"),
                       ("Tutte graph", "U: nx(tutte)"), ("Hoffman–Singleton", "U: nx(hoffman_singleton)"),
                       ("Les Misérables", "U: nx(les_miserables)"), ("25 isolated vertices", "U: E(25)"),
                       ("CFI over K4", "U: cfi(K(4))"), ("twisted CFI over K4", "U: cfi~(K(4))"),
                       ("directed C3", "D: C(0,1,2)"), ("Paley tournament 7", "D: tpaley(7)"),
                       ("transitive tournament 5", "D: tt(5)")]:
        R(Z, f"{name}: order", cell, None, "automorphismGroup().order")
        if not cell.startswith("U: E(25)") and "les_miserables" not in cell and "hoffman" not in cell:
            R(Z, f"{name}: orbits", cell, None, "automorphismGroup().orbits")
    R(Z, "Les Misérables: orbits", "U: nx(les_miserables)", None, "automorphismGroup().orbits")
    R(Z, "Petersen, one vertex coloured: order", "U: nx(petersen)", None, "automorphismGroup().order vertexColor: G [x,o,o,o,o,o,o,o,o,o]")
    R(Z, "Petersen, one vertex coloured: orbits", "U: nx(petersen)", None, "automorphismGroup().orbits vertexColor: G [x,o,o,o,o,o,o,o,o,o]")
    R(Z, "C4 with edge colours a a b b: order", "U: C(0,1,2,3)", None, "automorphismGroup().order edgeColor: G [a,a,b,b]")
    R(Z, "doubled edge and a pendant: order", "U: 0=1, 1-2", None, "automorphismGroup().order")
    R(Z, "loops break symmetry: orbits", "U: 0-0, C(0,1,2,3)", None, "automorphismGroup().orbits")
    R(Z, "bouquet of three loops: order", "U: 0-0, 0-0, 0-0", None, "automorphismGroup().order")


def render():
    lines = [HEADER]
    lines.append("| ID | Group | Case | G (pattern) | H (target) | Op | Expected |")
    lines.append("|---|---|---|---|---|---|---|")
    for r in ROWS:
        cells = [r[0], r[1], r[2], f"`{r[3]}`", f"`{r[4]}`" if r[4] else "—", f"`{r[5]}`", r[6]]
        lines.append("| " + " | ".join(c.replace("|", "\\|") for c in cells) + " |")
    lines.append("")
    lines.append(f"{len(ROWS)} rows.")
    return "\n".join(lines) + "\n"


HEADER = """# IsomorphismModule: case catalog (IS-001 – IS-{last:03d}, {count} rows)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
igraph==1.0.0 --with rustworkx==0.18.1 python3 Tests/Catalogs/Isomorphism/ref.py`; `--write`
regenerates this file, `--stress` adds random graphs). The model enumerates every mapping from the
definitions in api.md; rows with at most 7 target vertices are also checked against brute force
over every injection, and every matching row with at most 6,000 mappings is compared, as a set of
mappings, with NetworkX 3.7 (`GraphMatcher` and its directed and multigraph kinds, and the vf2pp
functions), python-igraph 1.0.0 (VF2 and LAD) and rustworkx 0.18.1 (`vf2_mapping`), each where it
supports the input. Disagreements are in api.md. Weisfeiler–Leman partitions are compared with
NetworkX's `weisfeiler_lehman_subgraph_hashes` and hash equality with its
`weisfeiler_lehman_graph_hash` on simple undirected rows. Automorphism group orders and orbits
come from enumeration and python-igraph's bliss, which must agree.

## Notation

**Graph**: `U:` undirected, `D:` directed. An optional vertex list in brackets comes first, then
edges in **position order**. `vertices` is the listed vertices, then the vertices of generators,
then endpoints by first appearance. Vertices are `Int`s.

| Token | Edges |
|---|---|
| `u-v`, `u>v`, `u=v` | one edge; one arc; two parallel edges u–v |
| `P(a,b,…)`, `C(a,b,…,z)` | the path a–b, b–c, …; the cycle a–b, …, z–a (arcs in a `D:` graph) |
| `S(c;a..b)` | the star c–a, …, c–b |
| `K(n)` | vertices 0..<n listed, every pair i < j, lexicographic |
| `KB(a..b;c..d)` | each of the first list to each of the second, row-major |
| `E(n)` | vertices 0..<n, no edges |
| `grid(r,c)` | vertices `i*c + j` listed; for each vertex in order the edge right, then down |
| `Q(d)` | hypercube: vertices 0..<2^d listed; for i in order, for k = 0..<d, i–(i ^ 2^k) when i < i ^ 2^k |
| `paley(q)` | vertices 0..<q listed; i–j for i < j when j − i is a nonzero square mod q (q prime, q ≡ 1 mod 4) |
| `tpaley(q)` | vertices 0..<q listed; i>j for every ordered pair when j − i is a nonzero square mod q (q ≡ 3 mod 4) |
| `tt(k)` | the transitive tournament: vertices 0..<k listed; i>j for i < j, lexicographic |
| `rook(k)` | K_k □ K_k: vertices `i*k + j` listed; a–b for a < b in one row or one column, lexicographic |
| `shrikhande` | the Cayley graph of Z4 × Z4 with connection set ±(1,0), ±(0,1), ±(1,1); vertex `4i + j` is (i, j); a–b for a < b, lexicographic |
| `cfi(B)`, `cfi~(B)` | the Cai–Fürer–Immerman graph over the base B (written in this notation); `~` twists B's first edge. Per base vertex v in index order: one middle vertex per even subset S of v's incident edges (as a bitmask over v's incidences in position order, ascending), then a(v, j, 0), a(v, j, 1) for each incidence j. Edges: per v, per S, per j, S–a(v, j, [j ∈ S]); then per base edge (u, w) in position order, a(u, j, i)–a(w, j′, i ⊕ t) for i = 0, 1, t = 1 only on the twisted edge |
| `nx(name)` | `networkx.<name>_graph()`: its `nodes` listed, then `edges()` in NetworkX's order |
| `lcg(n,m,s)` | vertices 0..<n, then m non-loop pairs from the 64-bit LCG of the Distances catalog, seeded s (parallel pairs possible) |
| `… ~map(a,b)` | the same graph relabelled: vertex x becomes (a·x + b) mod n (gcd(a, n) = 1), edges in the same positions, vertices 0..<n listed |
| `a..b` | every integer from a to b inclusive |

**Op** is the call `G.op(to: H)` (G is the pattern, the domain of every mapping), or `G.op` for
one-graph rows. `vertexColor: G [..] H [..]` passes `vertexColor:` (G's colours, in `vertices`
order) and `otherVertexColor:` (H's); `edgeColor:` likewise by edge position. `.count` is the
length of the lazy sequence. An `isomorphisms(to:)`-style op without `.count` is the whole sequence,
written as a set: **the order of the sequence is not pinned**, only its elements. `image(of:) after
isomorphism(to:)` runs the call, then the accessor on its result (those rows have exactly one
mapping).

**Expected.** A mapping is written as its images in G's `vertices` order: `[2, 0]` maps G's first
vertex to H's vertex 2. `some (one of #N)` means a mapping is returned and is not pinned: the test
checks it with the definition and checks that a second call returns the same one. `nil` is no
mapping. `#N` is a count. Weisfeiler–Leman partitions list, for each round r, the classes of
vertices with equal hashes, each class in `vertices` order, classes by their first vertex.
Hashes themselves are not pinned (api.md). `**trap**` rows are preconditions.

"""


def number_rows():
    for i, r in enumerate(ROWS):
        r[0] = f"IS-{i + 1:03d}"


def compute():
    slow = os.environ.get("ISO_TIMING")
    for r in ROWS:
        t0 = time.perf_counter()
        try:
            val = evaluate(r[3], r[4], r[5])
        except Trap as e:
            val = f"**trap** ({e})"
        r.append(val)
        if slow:
            print(f"{r[0]} {time.perf_counter() - t0:.2f}s", file=sys.stderr, flush=True)


# ============================================================================ stress

def random_graph(rng, n, directed, loops, multi):
    es = []
    for _ in range(rng.randrange(0, n * (n - 1) // (1 if directed else 2) + 1)):
        u, v = rng.randrange(n), rng.randrange(n)
        if u == v and not loops:
            continue
        k = (u, v) if directed else (min(u, v), max(u, v))
        if not multi and any(((a, b) if directed else (min(a, b), max(a, b))) == k for a, b in es):
            continue
        es.append((u, v))
    return G(directed, list(range(n)), es)


def relabel(g, rng):
    p = list(range(g.n))
    rng.shuffle(p)
    es = [(p[u], p[v]) for u, v in g.edges]
    rng.shuffle(es)
    return G(g.directed, list(range(g.n)), es)


def stress():
    rng = random.Random(20261011)
    checked = Counter()
    for trial in range(900):
        directed = trial % 3 == 1
        loops = trial % 5 == 0
        multi = trial % 7 == 0
        n = rng.randrange(0, 7)
        g = random_graph(rng, n, directed, loops, multi)
        h = relabel(g, rng) if rng.random() < 0.6 else random_graph(rng, n, directed, loops, multi)
        vc = None
        if rng.random() < 0.3 and n:
            vc = [rng.randrange(2) for _ in range(n)]
            vch = [None] * n
            # colour h consistently half of the time
            vch = [rng.randrange(2) for _ in range(n)]
        for mode, (p, t) in [("iso", (g, h)), ("induced", (random_graph(rng, rng.randrange(0, 4), directed, loops, multi), g)),
                             ("mono", (random_graph(rng, rng.randrange(0, 4), directed, loops, multi), g))]:
            a = vc if (mode == "iso" and vc is not None) else None
            b = vch if a is not None else None
            maps = match(p, t, mode, a, b)
            assert sorted(maps) == brute(p, t, mode, a, b), (trial, mode)
            cross_check(p, t, mode, maps, a, b, None, None, f"stress {trial} {mode}")
            checked[mode] += 1
        # WL: isomorphic graphs hash equal; partitions equal NetworkX's on simple undirected graphs
        k = rng.randrange(0, 4)
        intern = {}
        rg, rh = wl_rounds(g, k, None, None, intern), wl_rounds(h, k, None, None, intern)
        eq = all(Counter(x) == Counter(y) for x, y in zip(rg, rh))
        if match(g, h, "iso"):
            assert eq
        if not directed and g.is_simple() and k >= 1:
            hs = nx.weisfeiler_lehman_subgraph_hashes(to_nx(g)[0], iterations=k)
            for i in range(k):
                assert partition([hs[v][i] for v in range(g.n)], g.vertices) == partition(rg[i + 1], g.vertices)
            if h.is_simple() and k >= 2:
                a1 = nx.weisfeiler_lehman_graph_hash(to_nx(g)[0], iterations=k)
                b1 = nx.weisfeiler_lehman_graph_hash(to_nx(h)[0], iterations=k)
                assert (a1 == b1) == eq
        checked["wl"] += 1
        # automorphism orders against bliss on simple graphs
        if g.is_simple():
            gi = to_ig(g)
            assert gi.count_automorphisms() == len(match(g, g, "iso"))
            checked["aut"] += 1
    # larger isomorphic pairs: the model against the libraries' yes/no
    for trial in range(60):
        n = rng.randrange(8, 30)
        g = G(False, list(range(n)), lcg_edges(n, rng.randrange(n, 3 * n), rng.randrange(1 << 30)))
        g = G(False, g.vertices, list({(min(u, v), max(u, v)) for u, v in g.edges}))
        h = relabel(g, rng)
        f = match(g, h, "iso")
        assert f and is_valid(g, h, "iso", f[0])
        assert len(f) == to_ig(g).count_automorphisms()
        checked["larger"] += 1
    return checked


# ============================================================================ bench

BENCH = r'''
import sys, time, random, warnings; warnings.simplefilter("ignore")
import networkx as nx, igraph as ig, rustworkx as rx
sys.path.insert(0, {here!r})
import ref
case, lib = sys.argv[1], sys.argv[2]
g, h = ref.bench_pair(case)
def nxg(x):
    y = nx.Graph(); y.add_nodes_from(range(x.n)); y.add_edges_from(x.edges); return y
def igg(x): return ig.Graph(x.n, x.edges)
def rxg(x):
    y = rx.PyGraph(); y.add_nodes_from(range(x.n)); y.add_edges_from_no_data(x.edges); return y
if lib == "nx-vf2pp": a, b = nxg(g), nxg(h); f = lambda: nx.vf2pp_is_isomorphic(a, b)
elif lib == "nx-vf2": a, b = nxg(g), nxg(h); f = lambda: nx.is_isomorphic(a, b)
elif lib == "ig-vf2": a, b = igg(g), igg(h); f = lambda: a.isomorphic_vf2(b)
elif lib == "ig-bliss": a, b = igg(g), igg(h); f = lambda: a.isomorphic_bliss(b)
elif lib == "rx-vf2": a, b = rxg(g), rxg(h); f = lambda: rx.is_isomorphic(a, b)
elif lib == "ig-bliss-aut": a = igg(g); f = lambda: a.count_automorphisms()
elif lib == "ig-bliss-canon": a = igg(g); f = lambda: len(a.canonical_permutation())
t = time.perf_counter(); r = f(); t = time.perf_counter() - t
for _ in range(4 if t < 0.2 else 0):   # the best of five when a run is short
    u = time.perf_counter(); f(); t = min(t, time.perf_counter() - u)
print(f"{{t:.4f}} {{r}}")
'''


def bench_pair(case):
    rng = random.Random(7)
    if case.startswith("rrg"):
        d, n = map(int, case[3:].split("-"))
        x = nx.random_regular_graph(d, n, seed=1)
        g = G(False, list(range(n)), list(x.edges()))
        return g, relabel(g, rng)
    if case.startswith("paley"):
        g = parse_graph(f"U: paley({case[5:]})")
        return g, relabel(g, rng)
    if case == "srg16":
        return parse_graph("U: shrikhande"), relabel(parse_graph("U: rook(4)"), rng)
    if case.startswith("cfi"):
        n = int(case[3:].rstrip("t"))
        base = nx.random_regular_graph(3, n, seed=2)
        b = G(False, list(range(n)), list(base.edges()))
        cell = "U: " + ", ".join(f"{u}-{v}" for u, v in b.edges)
        g = parse_graph(f"U: cfi({cell[3:]})")
        h = parse_graph(f"U: cfi~({cell[3:]})") if case.endswith("t") else relabel(g, rng)
        return g, relabel(h, rng)
    if case.startswith("lsg"):
        # Latin-square graphs of Z_n and of Z_2 x Z_(n/2) (strongly regular, equal parameters):
        # "lsgN" against a relabelled copy, "lsgNt" against the other group's graph.
        n = int(case[3:].rstrip("t"))
        half = n // 2

        def lsg(op):
            return G(False, list(range(n * n)), [(a, b) for a in range(n * n) for b in range(a + 1, n * n)
                     if a // n == b // n or a % n == b % n or op(a // n, a % n) == op(b // n, b % n)])
        g = lsg(lambda a, b: (a + b) % n)
        h = lsg(lambda a, b: ((a // half + b // half) % 2) * half + (a % half + b % half) % half) if case.endswith("t") else g
        return g, relabel(h, rng)
    if case.startswith("union"):
        # 20 hexagons against 19 and two triangles ("unionc6"); 20 copies of K3,3 against 19 and
        # a prism ("unionk33").
        k = 20

        def cyc(m, o):
            return [(o + i, o + (i + 1) % m) for i in range(m)]

        def k33(o):
            return [(o + i, o + j) for i in range(3) for j in range(3, 6)]
        if case == "unionc6":
            a = sum((cyc(6, 6 * i) for i in range(k)), [])
            b = sum((cyc(6, 6 * i) for i in range(k - 1)), []) + cyc(3, 6 * k - 6) + cyc(3, 6 * k - 3)
        else:
            o = 6 * k - 6
            a = sum((k33(6 * i) for i in range(k)), [])
            b = sum((k33(6 * i) for i in range(k - 1)), []) + cyc(3, o) + cyc(3, o + 3) + [(o, o + 3), (o + 1, o + 4), (o + 2, o + 5)]
        return G(False, list(range(6 * k)), a), relabel(G(False, list(range(6 * k)), b), rng)
    if case.startswith("grid"):
        k = int(case[4:])
        g = parse_graph(f"U: grid({k},{k})")
        return g, relabel(g, rng)
    raise ValueError(case)


BENCH_CASES = ["rrg3-1000", "rrg3-10000", "rrg10-1000", "grid100", "paley101", "paley401", "srg16",
               "cfi10", "cfi10t", "cfi20", "cfi20t", "cfi40", "cfi40t", "lsg16", "lsg16t", "lsg24", "lsg24t",
               "unionc6", "unionk33"]


def export(directory):
    os.makedirs(directory, exist_ok=True)
    for c in BENCH_CASES:
        for side, x in zip("gh", bench_pair(c)):
            text = f"{x.n}\n" + "".join(f"{u} {v}\n" for u, v in x.edges)
            # Raw deflate, what Foundation's NSData.decompressed(using: .zlib) reads.
            packer = zlib.compressobj(9, zlib.DEFLATED, -15)
            with open(os.path.join(directory, f"{c}.{side}.deflate"), "wb") as f:
                f.write(packer.compress(text.encode()) + packer.flush())
        print("wrote", c)


def bench():
    cases = BENCH_CASES
    path = os.path.join(os.environ.get("TMPDIR", "/tmp"), "iso_bench_driver.py")
    open(path, "w").write(BENCH.format(here=HERE))
    libs = ["nx-vf2pp", "ig-vf2", "ig-bliss", "rx-vf2", "ig-bliss-aut", "ig-bliss-canon"]
    print("case | " + " | ".join(libs))
    for c in cases:
        row = []
        for lib in libs:
            try:
                out = subprocess.run([sys.executable, path, c, lib], capture_output=True, text=True, timeout=30)
                row.append(out.stdout.strip() or ("error: " + out.stderr.strip().splitlines()[-1][:40]))
            except subprocess.TimeoutExpired:
                row.append("> 30 s")
        print(c + " | " + " | ".join(row), flush=True)


# ============================================================================ main

def main():
    if "--bench" in sys.argv:
        bench()
        return
    if "--export" in sys.argv:
        export(sys.argv[sys.argv.index("--export") + 1])
        return
    define()
    number_rows()
    compute()
    global HEADER
    HEADER = HEADER.format(last=len(ROWS), count=len(ROWS))
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
    for (lib, why), k in sorted(DISAGREE.items()):
        print(f"  known disagreement, {k} rows: {lib}: {why}")
    if "--stress" in sys.argv:
        DISAGREE.clear()
        c = stress()
        print("stress: " + ", ".join(f"{k} {v}" for k, v in sorted(c.items())) +
              " checked against brute force, NetworkX, igraph and rustworkx")
        for (lib, why), k in sorted(DISAGREE.items()):
            print(f"  known disagreement, {k} cases: {lib}: {why}")


if __name__ == "__main__":
    main()
