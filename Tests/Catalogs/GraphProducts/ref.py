#!/usr/bin/env python3
"""Reference model for GraphProducts (Tests/Catalogs/GraphProducts).

Run: uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/GraphProducts/ref.py [--write] [--stress]

The four products are lazy views over two factors with dense vertex indices. Vertex (g, h) has
index g·|V(H)| + h (row-major, as NamedGraphs' grids number their vertices), every row is computed
from the factors' index rows with no hashing, and an edge's position names the factor edges and
vertices that generate it:

  Cartesian      (G, eG, h) for every edge eG of G and vertex h; then (H, g, eH)
  tensor         (T, eG, eH, crossed); undirected, a pair of non-loop edges gives two edges, the
                 straight {(a,c),(b,d)} and the crossed {(a,d),(b,c)}; with a loop they coincide and
                 there is one
  strong         the Cartesian positions, then the tensor positions
  lexicographic  (L, eG, h, h') for every edge eG of G and every h, h' (undirected over a loop at a:
                 only h ≤ h', since (a,h)–(a,h') and (a,h')–(a,h) are one edge); then (H, g, eH)

The model ports the factors (AdjacencyList-like, directed and undirected, positions 0..<m, parallel
edges and self-loops kept, an undirected self-loop listed twice in its row) and every label lookup
counts a hash. Each product is checked against
  * the definitions, edge by edge (the multiset of endpoint pairs);
  * NetworkX 3.7's cartesian_product, tensor_product, strong_product and lexicographic_product, on
    simple factors as Graph/DiGraph and on loopless factors as MultiGraph/MultiDiGraph (igraph 1.0's
    Python API has no product; its C `igraph_product` is the benchmark baseline instead);
  * NamedGraphs' grid numbering: P_r □ P_c is grid(r, c) with vertex (i, j) at i·c + j;
  * the DirectedGraph / BidirectionalDirectedGraph / Graph laws and the degree formulas;
  * the boundary law that index-space members hash nothing.
--write regenerates cases.md; without it the run fails if cases.md differs. --stress adds 400 random
factor pairs per product and direction.
"""
import os
import random
import sys

import networkx as nx

HERE = os.path.dirname(os.path.abspath(__file__))


class Trap(Exception):
    pass


def require(cond, msg):
    if not cond:
        raise Trap(msg)


INT_MAX = 2**63 - 1


# ---------------------------------------------------------------- factors (ports)

class Factor:
    def __init__(self, labels, edges, directed, indexed=True, count=None):
        self._labels = list(dict.fromkeys(list(labels) + [x for a in edges for x in a]))
        self._index = {l: i for i, l in enumerate(self._labels)}
        self.es = [(self._index[u], self._index[v]) for u, v in edges]
        self.directed = directed
        self.bidirectional = directed
        self.has_vertex_indices = indexed
        self._count = count  # a stand-in vertex count for the overflow rows
        self.hashes = 0

    def n(self):
        return self._count if self._count is not None else len(self._labels)

    def label(self, i):
        return self._labels[i]

    def vertex_index(self, label):
        self.hashes += 1
        require(label in self._index, f"{label} is not a vertex of the factor")
        return self._index[label]

    def positions(self):
        return list(range(len(self.es)))

    def ends(self, p):
        return self.es[p]

    def src(self, p):
        return self.es[p][0]

    def tgt(self, p):
        return self.es[p][1]

    def out_edges(self, i):
        return [p for p, (s, _) in enumerate(self.es) if s == i]

    def in_edges(self, i):
        return [p for p, (_, t) in enumerate(self.es) if t == i]

    def incident(self, i):
        row = []
        for p, (u, v) in enumerate(self.es):
            if u == i:
                row.append(p)
            if v == i:
                row.append(p)
        return row

    def is_loop(self, p):
        u, v = self.es[p]
        return u == v

    def other(self, p, i):
        u, v = self.es[p]
        return v if u == i else u

    def edge_bound(self):
        return len(self.es)


# ---------------------------------------------------------------- products

class Product:
    """One class for the four kinds; `kind` picks the rows, as the four Swift types would."""

    def __init__(self, kind, g, h):
        require(g.directed == h.directed, "both factors directed or both undirected")
        require(g.has_vertex_indices and h.has_vertex_indices, "a factor has no vertex indices (vertexIndexBound is nil)")
        ng, nh = g.n(), h.n()
        require(ng * nh <= INT_MAX, "the vertex count |V(G)|·|V(H)| overflows Int")
        self.kind, self.g, self.h = kind, g, h
        self.directed = g.directed
        self.bidirectional = g.directed
        self.nh = nh

    @property
    def hashes(self):
        return self.g.hashes + self.h.hashes

    @hashes.setter
    def hashes(self, value):
        self.g.hashes = value
        self.h.hashes = 0

    def n(self):
        return self.g.n() * self.h.n()

    def split(self, i):
        return divmod(i, self.nh)

    def join(self, a, b):
        return a * self.nh + b

    def label(self, i):
        a, b = self.split(i)
        return (self.g.label(a), self.h.label(b))

    def labels(self):
        return [self.label(i) for i in range(self.n())]

    def vertex_index(self, pair):
        return self.join(self.g.vertex_index(pair[0]), self.h.vertex_index(pair[1]))

    # -- positions, in `edges` order
    def _cart_positions(self):
        G, H = self.g, self.h
        return ([("G", e, b) for e in G.positions() for b in range(H.n())] +
                [("H", a, f) for a in range(G.n()) for f in H.positions()])

    def _tensor_positions(self):
        G, H = self.g, self.h
        out = []
        for e in G.positions():
            for f in H.positions():
                out.append(("T", e, f, 0))
                if not self.directed and not G.is_loop(e) and not H.is_loop(f):
                    out.append(("T", e, f, 1))
        return out

    def _lex_positions(self):
        G, H = self.g, self.h
        nh = H.n()
        out = []
        for e in G.positions():
            for b in range(nh):
                for b2 in range(nh):
                    if self.directed or not G.is_loop(e) or b <= b2:
                        out.append(("L", e, b, b2))
        return out + [("H", a, f) for a in range(G.n()) for f in H.positions()]

    def positions(self):
        if self.kind == "cartesian":
            return self._cart_positions()
        if self.kind == "tensor":
            return self._tensor_positions()
        if self.kind == "strong":
            return self._cart_positions() + self._tensor_positions()
        return self._lex_positions()

    # -- endpoints
    def ends(self, p):
        G, H = self.g, self.h
        if p[0] == "G":
            u, v = G.ends(p[1])
            return self.join(u, p[2]), self.join(v, p[2])
        if p[0] == "H":
            u, v = H.ends(p[2])
            return self.join(p[1], u), self.join(p[1], v)
        if p[0] == "T":
            a, b = G.ends(p[1])
            c, d = H.ends(p[2])
            return (self.join(a, c), self.join(b, d)) if p[3] == 0 else (self.join(a, d), self.join(b, c))
        a, b = G.ends(p[1])
        return self.join(a, p[2]), self.join(b, p[3])

    def src(self, p):
        return self.ends(p)[0]

    def tgt(self, p):
        return self.ends(p)[1]

    # -- rows, computed from the factor rows
    def _cart_row(self, a, b, out):
        G, H = self.g, self.h
        if out is None:
            return [("G", e, b) for e in G.incident(a)] + [("H", a, f) for f in H.incident(b)]
        rg = G.out_edges(a) if out else G.in_edges(a)
        rh = H.out_edges(b) if out else H.in_edges(b)
        return [("G", e, b) for e in rg] + [("H", a, f) for f in rh]

    def _tensor_row(self, a, b, out):
        G, H = self.g, self.h
        if out is not None:
            rg = G.out_edges(a) if out else G.in_edges(a)
            rh = H.out_edges(b) if out else H.in_edges(b)
            return [("T", e, f, 0) for e in rg for f in rh]
        row = []
        met_g = []
        for e in G.incident(a):
            if G.is_loop(e):
                if e in met_g:
                    continue  # a G-loop pairs once, from its first end
                met_g.append(e)
            met_h = []
            for f in H.incident(b):
                if H.is_loop(f) and not G.is_loop(e):
                    if f in met_h:
                        continue  # an H-loop with a non-loop eG pairs once
                    met_h.append(f)
                if G.is_loop(e) or H.is_loop(f):
                    row.append(("T", e, f, 0))
                else:
                    g_first = G.ends(e)[0] == a
                    h_first = H.ends(f)[0] == b
                    row.append(("T", e, f, 0 if g_first == h_first else 1))
        return row

    def _lex_row(self, a, b, out):
        G, H = self.g, self.h
        nh = H.n()
        row = []
        if out is not None:
            rg = G.out_edges(a) if out else G.in_edges(a)
            for e in rg:
                for b2 in range(nh):
                    row.append(("L", e, b, b2) if out else ("L", e, b2, b))
            rh = H.out_edges(b) if out else H.in_edges(b)
            return row + [("H", a, f) for f in rh]
        met = []
        for e in G.incident(a):
            if G.is_loop(e):
                if e not in met:
                    met.append(e)
                    row += [("L", e, min(b, b2), max(b, b2)) for b2 in range(nh)]
                else:
                    row.append(("L", e, b, b))  # the loop (a,b)–(a,b)'s second end
            elif G.ends(e)[0] == a:
                row += [("L", e, b, b2) for b2 in range(nh)]
            else:
                row += [("L", e, b2, b) for b2 in range(nh)]
        return row + [("H", a, f) for f in H.incident(b)]

    def _row(self, i, out):
        a, b = self.split(i)
        if self.kind == "cartesian":
            return self._cart_row(a, b, out)
        if self.kind == "tensor":
            return self._tensor_row(a, b, out)
        if self.kind == "strong":
            return self._cart_row(a, b, out) + self._tensor_row(a, b, out)
        return self._lex_row(a, b, out)

    def out_edges(self, i):
        return self._row(i, True)

    def in_edges(self, i):
        return self._row(i, False)

    def incident(self, i):
        return self._row(i, None)

    # -- counts and indices
    def edge_count(self):
        G, H = self.g, self.h
        ng, nh, mg, mh = G.n(), H.n(), len(G.es), len(H.es)
        cart = mg * nh + ng * mh
        if self.directed:
            tensor = mg * mh
            lex = mg * nh * nh + ng * mh
        else:
            lg = sum(1 for e in G.positions() if G.is_loop(e))
            lh = sum(1 for f in H.positions() if H.is_loop(f))
            tensor = 2 * mg * mh - (lg * mh + lh * mg - lg * lh)
            lex = (mg - lg) * nh * nh + lg * nh * (nh + 1) // 2 + ng * mh
        return {"cartesian": cart, "tensor": tensor, "strong": cart + tensor, "lexicographic": lex}[self.kind]

    def edge_bound(self):
        """Dense edge indices where they are arithmetic: Cartesian always, the other three
        directed only (undirected, a loop changes how many edges a factor pair yields)."""
        if self.kind == "cartesian" or self.directed:
            return self.edge_count()
        return None

    def edge_index(self, p):
        G, H = self.g, self.h
        ng, nh, mg, mh = G.n(), H.n(), len(G.es), len(H.es)
        cart = mg * nh + ng * mh
        if p[0] == "G":
            return p[1] * nh + p[2]
        if p[0] == "H":
            base = mg * nh * nh if self.kind == "lexicographic" else mg * nh
            return base + p[1] * mh + p[2]
        if p[0] == "T":
            return (cart if self.kind == "strong" else 0) + p[1] * mh + p[2]
        return p[1] * nh * nh + p[2] * nh + p[3]

    def contains_edge(self, i, j):
        for p in (self.out_edges(i) if self.directed else self.incident(i)):
            u, v = self.ends(p)
            if self.directed and v == j:
                return True
            if not self.directed and {u, v} == {i, j}:
                return True
        return False

    def degree(self, i):
        return len(self.incident(i)) if not self.directed else len(self.out_edges(i)) + len(self.in_edges(i))


# ---------------------------------------------------------------- laws

def check(p):
    before = p.hashes
    _check(p)
    assert p.hashes == before, "an index-space member hashed"


def _check(p):
    n = p.n()
    ps = p.positions()
    assert len(set(ps)) == len(ps)
    assert len(ps) == p.edge_count(), (len(ps), p.edge_count())
    for i in range(n):
        assert p.split(i) == divmod(i, p.nh) and p.join(*p.split(i)) == i
    if p.directed:
        for rows, end in ((p.out_edges, 0), (p.in_edges, 1)):
            seen = []
            for i in range(n):
                for q in rows(i):
                    assert p.ends(q)[end] == i
                seen += rows(i)
            assert sorted(seen) == sorted(ps), "rows list every edge once"
    else:
        count = {q: 0 for q in ps}
        for i in range(n):
            for q in p.incident(i):
                assert i in p.ends(q), (i, q, p.ends(q))
                count[q] += 1
        for q in ps:
            assert count[q] == 2, (q, count[q], p.kind)
    b = p.edge_bound()
    if b is not None:
        assert [p.edge_index(q) for q in ps] == list(range(b)), "edges in index order, indices dense"
    if not p.directed:
        G, H = p.g, p.h
        loopless = all(not G.is_loop(e) for e in G.positions()) and all(not H.is_loop(f) for f in H.positions())
        if loopless:
            for i in range(n):
                a, c = p.split(i)
                dg, dh, nh = len(G.incident(a)), len(H.incident(c)), H.n()
                want = {"cartesian": dg + dh, "tensor": dg * dh, "strong": dg + dh + dg * dh,
                        "lexicographic": dg * nh + dh}[p.kind]
                assert p.degree(i) == want


# ---------------------------------------------------------------- specs

def definition_edges(kind, G, H):
    """The product's edge multiset straight from the definition, as label pairs."""
    out = []
    VG, VH = range(G.n()), range(H.n())
    lab = lambda a, b: (G.label(a), H.label(b))
    norm = (lambda u, v: (u, v)) if G.directed else (lambda u, v: tuple(sorted((u, v), key=str)))
    if kind in ("cartesian", "strong"):
        out += [norm(lab(_g(G, e, 0), b), lab(_g(G, e, 1), b)) for e in G.positions() for b in VH]
        out += [norm(lab(a, H.ends(f)[0]), lab(a, H.ends(f)[1])) for a in VG for f in H.positions()]
    if kind in ("tensor", "strong"):
        for e in G.positions():
            (a, b2) = G.ends(e)
            for f in H.positions():
                (c, d) = H.ends(f)
                out.append(norm(lab(a, c), lab(b2, d)))
                if not G.directed and a != b2 and c != d:
                    out.append(norm(lab(a, d), lab(b2, c)))
    if kind == "lexicographic":
        for e in G.positions():
            (a, b2) = G.ends(e)
            for c in VH:
                for d in VH:
                    if G.directed or a != b2 or c <= d:
                        out.append(norm(lab(a, c), lab(b2, d)))
        out += [norm(lab(a, H.ends(f)[0]), lab(a, H.ends(f)[1])) for a in VG for f in H.positions()]
    return sorted(out, key=str)


def _g(G, e, k):
    return G.ends(e)[k]


def product_edges(p):
    norm = (lambda u, v: (u, v)) if p.directed else (lambda u, v: tuple(sorted((u, v), key=str)))
    return sorted((norm(p.label(p.ends(q)[0]), p.label(p.ends(q)[1])) for q in p.positions()), key=str)


NX = {"cartesian": nx.cartesian_product, "tensor": nx.tensor_product, "strong": nx.strong_product,
      "lexicographic": nx.lexicographic_product}


def to_nx(F, multi):
    cls = (nx.MultiDiGraph if F.directed else nx.MultiGraph) if multi else (nx.DiGraph if F.directed else nx.Graph)
    X = cls()
    X.add_nodes_from(F.label(i) for i in range(F.n()))
    for p in F.positions():
        u, v = F.ends(p)
        if multi:
            X.add_edge(F.label(u), F.label(v), key=p)
        else:
            X.add_edge(F.label(u), F.label(v))
    return X


def is_simple(F):
    seen = set()
    for p in F.positions():
        u, v = F.ends(p)
        k = (u, v) if F.directed else frozenset((u, v))
        if u == v or k in seen:
            return False
        seen.add(k)
    return True


def has_loop(F):
    return any(u == v for u, v in F.es)


def nx_edges(P, directed):
    norm = (lambda u, v: (u, v)) if directed else (lambda u, v: tuple(sorted((u, v), key=str)))
    return sorted((norm(u, v) for u, v in P.edges()), key=str)


def spec(p):
    G, H = p.g, p.h
    ours = product_edges(p)
    assert ours == definition_edges(p.kind, G, H), p.kind
    assert sorted(map(str, p.labels())) == sorted(map(str, NX[p.kind](to_nx(G, False), to_nx(H, False)).nodes()))
    if is_simple(G) and is_simple(H):
        assert ours == nx_edges(NX[p.kind](to_nx(G, False), to_nx(H, False)), p.directed)
    if not has_loop(G) and not has_loop(H):
        assert ours == nx_edges(NX[p.kind](to_nx(G, True), to_nx(H, True)), p.directed), p.kind


def nx_multi_note(p):
    """NetworkX's MultiGraph count when it differs (it merges product edges that share their ends and
    the factor edge's key, which happens only around self-loops)."""
    if p.directed:
        return ""
    k = NX[p.kind](to_nx(p.g, True), to_nx(p.h, True)).number_of_edges()
    return "" if k == p.edge_count() else f" (NetworkX MultiGraph: {k}, merging coincident loop products)"


# ---------------------------------------------------------------- formatting

def fmt_pos(q):
    if q[0] == "G":
        return f"G{q[1]}·{q[2]}"
    if q[0] == "H":
        return f"{q[1]}·H{q[2]}"
    if q[0] == "T":
        return f"G{q[1]}×H{q[2]}" + ("'" if q[3] else "")
    return f"G{q[1]}·{q[2]}{q[3]}"


def fmt_label(l):
    return f"({l[0]},{l[1]})"


def fmt_state(p, show_edges=True):
    vs = ", ".join(f"{fmt_label(p.label(i))}#{i}" for i in range(p.n()))
    b = p.edge_bound()
    s = f"V [{vs}]"
    if show_edges:
        arrow = "→" if p.directed else "–"
        es = ", ".join(f"{fmt_pos(q)}:{fmt_label(p.label(p.ends(q)[0]))}{arrow}{fmt_label(p.label(p.ends(q)[1]))}"
                       for q in p.positions())
        s += f"; E [{es}]"
    return s + f"; edgeCount {p.edge_count()}; bounds {p.n()}/{'nil' if b is None else b}"


def fmt_rows(p):
    out = []
    for i in range(p.n()):
        if p.directed:
            row = [fmt_label(p.label(p.tgt(q))) for q in p.out_edges(i)]
        else:
            row = []
            for q in p.incident(i):
                u, v = p.ends(q)
                row.append(fmt_label(p.label(v if u == i else u)))
        out.append(f"{fmt_label(p.label(i))}: " + " ".join(row))
    return "rows [" + "; ".join(out) + "]"


# ---------------------------------------------------------------- cases

ROWS = []
NAMES = {"cartesian": "cartesianProduct", "tensor": "tensorProduct", "strong": "strongProduct",
         "lexicographic": "lexicographicProduct"}


def row(group, title, inp, exp):
    ROWS.append((f"GP-{len(ROWS) + 1:03d}", group, title, inp, exp))


def D(vs, es):
    E = [tuple(x.split(">")) for x in es.split()] if es else []
    return Factor(vs.split() if vs else [], E, True), f"AL V [{', '.join(vs.split())}]; E [{', '.join(a + '→' + b for a, b in E)}]"


def UU(vs, es):
    E = [tuple(x.split("-")) for x in es.split()] if es else []
    return Factor(vs.split() if vs else [], E, False), f"UL V [{', '.join(vs.split())}]; E [{', '.join(a + '–' + b for a, b in E)}]"


def case(group, title, kind, gf, hf, rows=True, edges=True, extra=None):
    (g, gt), (h, ht) = gf, hf
    try:
        p = Product(kind, g, h)
        check(p)
        spec(p)
        exp = fmt_state(p, edges) + nx_multi_note(p)
        if rows:
            exp += "; " + fmt_rows(p)
        if extra:
            exp += "; " + extra(p)
    except Trap as t:
        exp = f"**trap** ({t})"
    row(group, title, f"G = {gt}; H = {ht} / {NAMES[kind]}(G, H)", exp)


def define():
    K = ["cartesian", "tensor", "strong", "lexicographic"]
    Gr = {"cartesian": "Cartesian", "tensor": "Tensor", "strong": "Strong", "lexicographic": "Lexicographic"}
    for k in K:
        G = Gr[k]
        case(G, "empty factor: empty product", k, UU("", ""), UU("x y", "x-y"))
        case(G, "K1 is the identity for vertices", k, UU("a", ""), UU("x y", "x-y"))
        case(G, "K2 with K2", k, UU("a b", "a-b"), UU("x y", "x-y"))
        case(G, "P3 with K2", k, UU("a b c", "a-b b-c"), UU("x y", "x-y"), rows=False)
        case(G, "edgeless factors", k, UU("a b", ""), UU("x y", ""), rows=False)
        case(G, "directed: K2 arc with K2 arc", k, D("a b", "a>b"), D("x y", "x>y"))
        case(G, "directed: 2-cycle with an arc", k, D("a b", "a>b b>a"), D("x y", "x>y"), rows=False)
        case(G, "directed: predecessors from the factors' in-rows", k, D("a b", "a>b"), D("x y", "x>y"), rows=False, edges=False,
             extra=lambda p: "predecessors(of: (b,y)) [" + ", ".join(fmt_label(p.label(p.src(q))) for q in p.in_edges(3)) + "]")
        case(G, "undirected: self-loop in G", k, UU("a b", "a-a a-b"), UU("x y", "x-y"))
        case(G, "undirected: self-loop in H", k, UU("a b", "a-b"), UU("x y", "x-x x-y"))
        case(G, "undirected: self-loops in both", k, UU("a", "a-a"), UU("x", "x-x"))
        case(G, "undirected: parallel edges in G", k, UU("a b", "a-b b-a"), UU("x y", "x-y"), rows=False)
        case(G, "directed: self-loop in G", k, D("a b", "a>a a>b"), D("x y", "x>y"), rows=False)
        case(G, "rows and lookups: index-space rows hash nothing, a pair lookup hashes twice", k,
             UU("a b c", "a-b b-c"), UU("x y", "x-y"), rows=False, edges=False,
             extra=lambda p: _hash_probe(p))
    # identities and classical families
    G = "Identities"
    case(G, "P2 □ P3 is grid(2, 3): vertex (i, j) at i·3 + j", "cartesian", UU("0 1", "0-1"), UU("0 1 2", "0-1 1-2"),
         edges=False, extra=lambda p: _grid_note(p, 2, 3))
    case(G, "K2 □ K2 □ K2 nests: Q3 has 12 edges (cube)", "cartesian", UU("a b", "a-b"), UU("x y", "x-y"), rows=False,
         edges=False, extra=lambda p: "nested with K2: edgeCount " + str(Product("cartesian", _Mat(p), Factor(["0", "1"], [("0", "1")], False)).edge_count()))
    case(G, "K2 × C3 is C6 (bipartite double cover)", "tensor", UU("a b", "a-b"), UU("x y z", "x-y y-z z-x"))
    case(G, "K2 × K2 is two disjoint edges", "tensor", UU("a b", "a-b"), UU("x y", "x-y"), rows=False)
    case(G, "K2 ⊠ K2 is K4", "strong", UU("a b", "a-b"), UU("x y", "x-y"), rows=False)
    case(G, "K2 ∘ edgeless 2 is C4 (K2,2)", "lexicographic", UU("a b", "a-b"), UU("x y", ""))
    case(G, "edgeless 2 ∘ K2 is two disjoint edges", "lexicographic", UU("a b", ""), UU("x y", "x-y"), rows=False)
    case(G, "lexicographic is not commutative: P3 ∘ K2 has 11 edges, K2 ∘ P3 has 13", "lexicographic",
         UU("a b c", "a-b b-c"), UU("x y", "x-y"), rows=False, edges=False,
         extra=lambda p: "swapped edgeCount " + str(Product("lexicographic", p.h, p.g).edge_count()))
    # indices and traps
    G = "Indices"
    case(G, "vertex(atIndex:) by one division; vertexIndex(of:) two factor lookups", "cartesian",
         UU("a b c", "a-b"), UU("x y", "x-y"), rows=False, edges=False,
         extra=lambda p: f"vertex(atIndex: 5) {fmt_label(p.label(5))}; vertexIndex(of: (b,x)) {p.vertex_index(('b', 'x'))}")
    case(G, "edgeIndex: Cartesian G-part then H-part", "cartesian", D("a b", "a>b"), D("x y z", "x>y y>z"), rows=False,
         extra=lambda p: "edgeIndex [" + ", ".join(f"{fmt_pos(q)}: {p.edge_index(q)}" for q in p.positions()) + "]")
    case(G, "edgeIndex: directed strong is Cartesian then tensor", "strong", D("a b", "a>b"), D("x y", "x>y"), rows=False,
         extra=lambda p: "edgeIndex [" + ", ".join(f"{fmt_pos(q)}: {p.edge_index(q)}" for q in p.positions()) + "]")
    case(G, "undirected tensor has no edge indices", "tensor", UU("a b", "a-b"), UU("x y", "x-y"), rows=False, edges=False)
    for title, gf, hf in [
        ("factor without vertex indices traps (phase 1)", (Factor(["a"], [], True, indexed=False), "Stable (with holes) V [a]; E []"), D("x", "")),
        ("vertex count overflow traps", (Factor(["a"], [], False, count=2**32), "a factor with 2^32 vertices"),
         (Factor(["x"], [], False, count=2**32), "a factor with 2^32 vertices")),
    ]:
        try:
            Product("cartesian", gf[0], hf[0])
            exp = "no trap"
        except Trap as t:
            exp = f"**trap** ({t})"
        row(G, title, f"G = {gf[1]}; H = {hf[1]} / cartesianProduct(G, H)", exp)
    p = Product("cartesian", *[f for f, _ in (UU("a b", "a-b"), UU("x", ""))])
    try:
        p.vertex_index(("a", "q"))
        exp = "no trap"
    except Trap as t:
        exp = f"**trap** ({t})"
    row(G, "a pair with a vertex not in its factor traps", "G = UL V [a, b]; E [a–b]; H = UL V [x]; E [] / "
        "cartesianProduct(G, H).vertexIndex(of: Pair(a, q))", exp)


class _Mat(Factor):
    """A product read as a factor (the nesting a Swift caller gets by passing the view itself)."""

    def __init__(self, p):
        labels = [str(p.label(i)) for i in range(p.n())]
        edges = [(labels[p.ends(q)[0]], labels[p.ends(q)[1]]) for q in p.positions()]
        Factor.__init__(self, labels, edges, p.directed)


def _hash_probe(p):
    p.hashes = 0
    rows = [p.incident(i) for i in range(p.n())]
    a = p.hashes
    p.vertex_index(("b", "y"))
    return f"all rows: hashes {a}; vertexIndex(of: (b,y)): hashes {p.hashes - a}"


def _grid_note(p, r, c):
    grid = set()
    for i in range(r):
        for j in range(c):
            v = i * c + j
            if i + 1 < r:
                grid.add((v, v + c))
            if j + 1 < c:
                grid.add((v, v + 1))
    ours = {tuple(sorted(p.ends(q))) for q in p.positions()}
    assert ours == grid
    assert all(p.label(i) == (str(i // c), str(i % c)) for i in range(r * c))
    return f"index-space edges equal NamedGraphs grid(dimensions: [{r}, {c}]): true"


# ---------------------------------------------------------------- output

def render():
    out = [
        "# GraphProducts: case catalog (phase 1)",
        "",
        "Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0",
        "python3 Tests/Catalogs/GraphProducts/ref.py`; `--write` regenerates this file, `--stress` adds the random",
        "factor pairs). Every product is checked against its definition edge by edge, NetworkX 3.7's four product",
        "functions (simple factors, and loopless multigraph factors), the protocol laws, the degree formulas, and",
        "the boundary law that index-space members hash nothing.",
        "",
        "Conventions:",
        "",
        "* `AL V [...]; E [...]` is a factor `AdjacencyList<String>` (with parallel arcs or self-loops,",
        "  `DirectedPseudograph<String>`); `UL` is `UndirectedAdjacencyList<String>` (`Pseudograph<String>`).",
        "  Factor edge positions are `0..<m` in the listed order. `Stable (with holes)` has `vertexIndexBound == nil`.",
        "* State: `V [(g,h)#i, …]` is `vertices` (`Pair(g, h)`) with `vertexIndex(of:)`, i = index(g)·|V(H)| + index(h).",
        "  `E [pos:(g,h)→(g',h'), …]` is `edges` in order with positions: `Gk·h` is G's edge k at H-vertex index h,",
        "  `g·Hk` is H's edge k at G-vertex index g, `Gk×Hl` is the tensor edge of G's k and H's l (`'` marks the",
        "  crossed one of an undirected pair), `Gk·hh'` the lexicographic edge of G's k from H-index h to h'.",
        "  `bounds a/b` is `vertexIndexBound` / `edgeIndexBound`. `rows [v: w …]` lists `successors(of:)`",
        "  (undirected: `neighbors(of:)`), a self-loop twice.",
        "* `hashes` counts factor label lookups. It is a benchmark counter, not API: the Swift suite checks it with",
        "  a vertex type whose `hash(into:)` counts.",
        "* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`).",
        "",
        "| ID | Group | Case | Input / call | Expected |",
        "|---|---|---|---|---|",
    ]
    for r in ROWS:
        out.append("| " + " | ".join(x.replace("|", "\\|") for x in r) + " |")
    return "\n".join(out) + "\n"


def stress():
    rng = random.Random(20261011)
    pool = [str(i) for i in range(5)]
    count = 0
    for _ in range(400):
        for directed in (True, False):
            fs = []
            for _ in range(2):
                n = rng.randrange(0, 5)
                vs = pool[:n]
                m = rng.randrange(0, 6) if n else 0
                fs.append(Factor(vs, [(rng.choice(vs), rng.choice(vs)) for _ in range(m)], directed))
            for k in ("cartesian", "tensor", "strong", "lexicographic"):
                p = Product(k, fs[0], fs[1])
                check(p)
                spec(p)
                count += 1
    return count


def main():
    define()
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
    if "--stress" in sys.argv:
        k = stress()
        print(f"stress: {k} random products (4 kinds x directed/undirected) agree with the definitions, "
              f"NetworkX and the laws")


if __name__ == "__main__":
    main()
