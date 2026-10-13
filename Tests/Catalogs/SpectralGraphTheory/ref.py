#!/usr/bin/env python3
"""Reference model for SpectralGraphTheory (Tests/Catalogs/SpectralGraphTheory).

Run: uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with numpy==2.5.4 \
         python3 Tests/Catalogs/SpectralGraphTheory/ref.py [--write] [--stress] [--bench]

The model works in index space, from the definitions in api.md:

  * A (adjacency): A[u][v] is the summed weight of the edges u–v (arcs u→v); an undirected self-loop
    adds 2w to A[u][u] (its two ends, Graph's degree rule), a directed one adds w. Unweighted, w = 1.
  * D = diag(row sums of A); L = D − A (loops cancel); N = D^-1/2 L D^-1/2 and L_rw = D^-1 L, with a
    zero row and column at a vertex of zero degree; Q = D + A (signless).
  * Spectra: numpy.linalg.eigvalsh of the dense symmetric matrix, ascending. Fiedler vector: the
    eigenvector of λ₂ when λ₂ is simple and the graph connected, with the canonical sign (api.md).
  * Spanning-tree counts, resistance distances and effective graph resistance exactly, in
    fractions: τ(G) = det of L with one row and column removed (Bareiss); R(u, v) = τ(G/uv) / τ(G)
    on u's component (G/uv: u and v identified); effective graph resistance = Σ_{u<v} R(u, v).

Independent checks on every row: closed forms for the named families (K_n, P_n, C_n, stars,
K_{m,n}, hypercubes, grids, Petersen), brute-force spanning-tree enumeration (m ≤ 16) and the
Moore–Penrose pseudoinverse for resistances, and NetworkX 3.7 (matrices, spectra,
algebraic_connectivity, fiedler_vector, spectral_ordering, number_of_spanning_trees,
resistance_distance, effective_graph_resistance, kemeny_constant, spectral_bisection) and SciPy
1.18.1 (csgraph.laplacian, eigsh) wherever they share the semantics; the known disagreements are
counted in DISAGREE. --write regenerates cases.md; without it the run fails if
cases.md differs. --stress adds random multigraphs with loops and weights. --bench prints
baseline timings (several minutes).
"""
import itertools
import math
import os
import re
import signal
import sys
import time
import warnings
from collections import Counter
from fractions import Fraction

warnings.simplefilter("ignore")

import networkx as nx  # noqa: E402
import numpy as np  # noqa: E402
import scipy as sp  # noqa: E402
import scipy.sparse.csgraph  # noqa: E402,F401
import scipy.sparse.linalg  # noqa: E402,F401

HERE = os.path.dirname(os.path.abspath(__file__))
MASK = (1 << 64) - 1
DISAGREE = Counter()
METHODS = ("tracemin_pcg", "lanczos", "lobpcg")   # --stress uses tracemin_lu alone (speed)


class Trap(Exception):
    pass


# ============================================================================ graphs

class G:
    """Index space: vertex names in `vertices` order; edges (u, v) by index in position order."""

    def __init__(self, directed, vertices, edges):
        self.directed = directed
        self.vertices = list(vertices)
        self.n = len(self.vertices)
        self.edges = list(edges)
        self.m = len(self.edges)

    def has_loops(self):
        return any(u == v for u, v in self.edges)

    def is_simple(self):
        seen = set()
        for u, v in self.edges:
            k = (u, v) if self.directed else (min(u, v), max(u, v))
            if u == v or k in seen:
                return False
            seen.add(k)
        return True


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
    if t.startswith("E("):
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
    if t.startswith("Q("):
        d = int(t[2:-1])
        return list(range(1 << d)), [(i, i ^ (1 << k)) for i in range(1 << d) for k in range(d) if i < i ^ (1 << k)]
    if t.startswith("nx("):
        g = getattr(nx, t[3:-1] + "_graph")()
        return list(g.nodes), list(g.edges())
    if t.startswith("lcg("):
        n, m, s = map(int, t[4:-1].split(","))
        return list(range(n)), lcg_edges(n, m, s)
    m = re.fullmatch(r"(-?\w+)([->=])(-?\w+)", t)
    assert m, f"bad token {t!r}"
    a, b = items(m.group(1))[0], items(m.group(3))[0]
    if m.group(2) == "=":
        return [], [(a, b), (a, b)]
    return [], [(a, b)]


def parse_graph(cell):
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
    num = {v: i for i, v in enumerate(vs)}
    return G(kind.strip() == "D", vs, [(num[x], num[y]) for x, y in pairs])


# ============================================================================ the model

def check_weights(g, w, allow_negative=False):
    if w is None:
        return [Fraction(1)] * g.m
    assert len(w) == g.m, "one weight per edge position"
    out = []
    for x in w:
        if isinstance(x, float) and not math.isfinite(x):
            raise Trap("weight not finite")
        if not allow_negative and x < 0:
            raise Trap("negative weight")
        out.append(Fraction(x) if not isinstance(x, float) else Fraction(str(x)))
    return out


def adjacency(g, w):
    n = g.n
    A = [[Fraction(0)] * n for _ in range(n)]
    for (u, v), x in zip(g.edges, w):
        if g.directed:
            A[u][v] += x
        elif u == v:
            A[u][u] += 2 * x
        else:
            A[u][v] += x
            A[v][u] += x
    return A


def degrees(A):
    return [sum(r) for r in A]


def laplacian(g, w):
    A = adjacency(g, w)
    d = degrees(A)
    return [[(d[i] if i == j else 0) - A[i][j] for j in range(g.n)] for i in range(g.n)]


def signless(g, w):
    A = adjacency(g, w)
    d = degrees(A)
    return [[(d[i] if i == j else 0) + A[i][j] for j in range(g.n)] for i in range(g.n)]


def normalized(g, w):
    A = adjacency(g, w)
    d = [float(x) for x in degrees(A)]
    L = laplacian(g, w)
    s = [1 / math.sqrt(x) if x > 0 else 0.0 for x in d]
    return [[s[i] * float(L[i][j]) * s[j] for j in range(g.n)] for i in range(g.n)]


def random_walk(g, w):
    A = adjacency(g, w)
    d = degrees(A)
    L = laplacian(g, w)
    return [[(L[i][j] / d[i]) if d[i] != 0 else Fraction(0) for j in range(g.n)] for i in range(g.n)]


def eigvalsh(M):
    if not M:
        return []
    return [float(x) for x in np.linalg.eigvalsh(np.array(M, dtype=float))]


def components(g, w):
    """Components by positive-weight edges, each in index order, ordered by least index."""
    parent = list(range(g.n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for (u, v), x in zip(g.edges, w):
        if x > 0:
            parent[find(u)] = find(v)
    groups = {}
    for v in range(g.n):
        groups.setdefault(find(v), []).append(v)
    return sorted(groups.values(), key=lambda c: c[0])


def det(M):
    """Exact determinant (Fraction Gaussian elimination)."""
    M = [row[:] for row in M]
    n = len(M)
    out = Fraction(1)
    for c in range(n):
        p = next((r for r in range(c, n) if M[r][c] != 0), None)
        if p is None:
            return Fraction(0)
        if p != c:
            M[c], M[p] = M[p], M[c]
            out = -out
        out *= M[c][c]
        for r in range(c + 1, n):
            if M[r][c] != 0:
                f = M[r][c] / M[c][c]
                for k in range(c, n):
                    M[r][k] -= f * M[c][k]
    return out


def spanning_trees(g, w):
    """τ(G): Σ over spanning trees of the product of weights; 0 for the empty graph."""
    if g.n == 0:
        return Fraction(0)
    L = laplacian(g, w)
    return det([row[1:] for row in L[1:]])


def contract(g, w, u, v):
    """G with u and v identified (loops dropped: they never lie on a spanning tree)."""
    ren = [x if x != v else u for x in range(g.n)]
    keep = [x for x in range(g.n) if x != v]
    num = {x: i for i, x in enumerate(keep)}
    es, ws = [], []
    for (a, b), x in zip(g.edges, w):
        a, b = num[ren[a]], num[ren[b]]
        if a != b:
            es.append((a, b))
            ws.append(x)
    return G(False, keep, es), ws


def resistance(g, w, u, v):
    if u == v:
        return Fraction(0)
    comp = next(c for c in components(g, w) if u in c)
    if v not in comp:
        return None
    num = {x: i for i, x in enumerate(comp)}
    es, ws = [], []
    for (a, b), x in zip(g.edges, w):
        if a in num and x > 0:
            es.append((num[a], num[b]))
            ws.append(x)
    h = G(False, comp, es)
    hc, hw = contract(h, ws, num[u], num[v])
    return spanning_trees(hc, hw) / spanning_trees(h, ws)


def effective_graph_resistance(g, w):
    if len(components(g, w)) > 1:
        return None
    return sum((resistance(g, w, u, v) for u in range(g.n) for v in range(u + 1, g.n)), Fraction(0))


def scale_of(vals):
    return max([1.0] + [abs(x) for x in vals])


def lam2(g, w, norm):
    if g.n < 2:
        raise Trap("fewer than two vertices")
    M = normalized(g, w) if norm else laplacian(g, w)
    return eigvalsh(M)[1]


def canonical_sign(x):
    big = max(abs(t) for t in x)
    for t in x:
        if abs(t) >= 1e-4 * big:
            return x if t > 0 else [-s for s in x]
    return x


def fiedler(g, w, norm):
    """None when disconnected; ('degenerate', λ₂, multiplicity) when λ₂ is not simple; else
    (λ₂, canonical vector)."""
    if g.n < 2:
        raise Trap("fewer than two vertices")
    if len(components(g, w)) > 1:
        return None
    M = normalized(g, w) if norm else laplacian(g, w)
    vals, vecs = np.linalg.eigh(np.array(M, dtype=float))
    s = scale_of(vals)
    mult = sum(1 for x in vals if abs(x - vals[1]) <= 1e-8 * s)
    if mult > 1:
        return ("degenerate", float(vals[1]), mult)
    return (float(vals[1]), canonical_sign([float(t) for t in vecs[:, 1]]))


def induced(g, w, comp):
    num = {x: i for i, x in enumerate(comp)}
    es, ws = [], []
    for (a, b), x in zip(g.edges, w):
        if a in num and b in num:
            es.append((num[a], num[b]))
            ws.append(x)
    return G(False, [g.vertices[x] for x in comp], es), ws


def spectral_ordering(g, w, norm=False):
    """Components by least index; a component of more than 2 vertices sorted by its Fiedler
    vector (canonical sign), entries within 1e-8 · max|x| of the previous one kept in index order;
    returns (order, tied?) where tied means the order relied on that rule or on a degenerate λ₂."""
    if g.n == 0:
        return [], False
    order, tied = [], False
    for comp in components(g, w):
        if len(comp) <= 2:
            order += comp
            continue
        h, hw = induced(g, w, comp)
        f = fiedler(h, hw, norm)
        if f[0] == "degenerate":
            vals, vecs = np.linalg.eigh(np.array(normalized(h, hw) if norm else laplacian(h, hw), dtype=float))
            x = canonical_sign([float(t) for t in vecs[:, 1]])
            tied = True
        else:
            x = f[1]
        big = max(abs(t) for t in x)
        idx = sorted(range(len(comp)), key=lambda i: x[i])
        runs, cur = [], [idx[0]]
        for a, b in zip(idx, idx[1:]):
            if x[b] - x[a] <= 1e-8 * big:
                cur.append(b)
                tied = True
            else:
                runs.append(cur)
                cur = [b]
        runs.append(cur)
        order += [comp[i] for r in runs for i in sorted(r)]
    return order, tied


def kemeny(g, w):
    if g.n == 0:
        return 0.0
    if len(components(g, w)) > 1:
        return None
    vals = eigvalsh(normalized(g, w))
    return float(sum(1 / x for x in vals[1:]))


def spectral_radius(g, w):
    vals = eigvalsh(adjacency(g, w))
    return max([0.0] + [abs(x) for x in vals])


def arborescences(g, w, root):
    """Directed: Σ over spanning arborescences directed away from `root` (each other vertex has
    one entering arc) of the product of weights; Tutte's matrix-tree theorem on the in-degree
    Laplacian."""
    n = g.n
    A = adjacency(g, w)
    for i in range(n):
        A[i][i] = Fraction(0)             # loops never lie on an arborescence
    indeg = [sum(A[i][j] for i in range(n)) for j in range(n)]
    L = [[(indeg[i] if i == j else 0) - A[i][j] for j in range(n)] for i in range(n)]
    keep = [x for x in range(n) if x != root]
    return det([[L[i][j] for j in keep] for i in keep])


def bisection(g, w):
    f = fiedler(g, w, False)
    if f is None or f[0] == "degenerate":
        return f
    x = f[1]
    big = max(abs(t) for t in x)
    neg = [g.vertices[i] for i in range(g.n) if x[i] < -1e-8 * big]
    return neg, [g.vertices[i] for i in range(g.n) if x[i] >= -1e-8 * big]


# ============================================================================ brute-force and closed-form oracles

def brute_spanning_trees(g, w):
    if g.n == 0:
        return Fraction(0)
    total = Fraction(0)
    idx = [p for p, (u, v) in enumerate(g.edges) if u != v]
    for sub in itertools.combinations(idx, g.n - 1):
        parent = list(range(g.n))

        def find(x):
            while parent[x] != x:
                x = parent[x]
            return x
        ok = True
        for p in sub:
            a, b = find(g.edges[p][0]), find(g.edges[p][1])
            if a == b:
                ok = False
                break
            parent[a] = b
        if ok:
            prod = Fraction(1)
            for p in sub:
                prod *= w[p]
            total += prod
    return total


def brute_arborescences(g, w, root):
    total = Fraction(0)
    choices = []
    for v in range(g.n):
        if v == root:
            continue
        choices.append([p for p, (a, b) in enumerate(g.edges) if b == v and a != v])
    for pick in itertools.product(*choices):
        parent = {}
        for p in pick:
            a, b = g.edges[p]
            parent[b] = a
        ok = True
        for v in range(g.n):
            seen, x = set(), v
            while x != root:
                if x in seen:
                    ok = False
                    break
                seen.add(x)
                x = parent[x]
            if not ok:
                break
        if ok:
            prod = Fraction(1)
            for p in pick:
                prod *= w[p]
            total += prod
    return total


def closed_form(cell, op):
    """The Laplacian / adjacency / normalized spectra of named families, or None."""
    c = cell.replace("U: ", "")
    m = re.fullmatch(r"K\((\d+)\)", c)
    if m:
        n = int(m.group(1))
        return {"laplacianSpectrum()": [0.0] + [n] * (n - 1), "adjacencySpectrum()": [-1.0] * (n - 1) + [n - 1],
                "normalizedLaplacianSpectrum()": [0.0] + [n / (n - 1)] * (n - 1) if n > 1 else [0.0]}.get(op)
    m = re.fullmatch(r"P\(0\.\.(\d+)\)", c)
    if m:
        n = int(m.group(1)) + 1
        return {"laplacianSpectrum()": sorted(2 - 2 * math.cos(math.pi * k / n) for k in range(n)),
                "adjacencySpectrum()": sorted(2 * math.cos(math.pi * k / (n + 1)) for k in range(1, n + 1)),
                "normalizedLaplacianSpectrum()": sorted(1 - math.cos(math.pi * k / (n - 1)) for k in range(n))}.get(op)
    m = re.fullmatch(r"C\(0\.\.(\d+)\)", c)
    if m:
        n = int(m.group(1)) + 1
        return {"laplacianSpectrum()": sorted(2 - 2 * math.cos(2 * math.pi * k / n) for k in range(n)),
                "adjacencySpectrum()": sorted(2 * math.cos(2 * math.pi * k / n) for k in range(n)),
                "normalizedLaplacianSpectrum()": sorted(1 - math.cos(2 * math.pi * k / n) for k in range(n))}.get(op)
    m = re.fullmatch(r"S\(0;1\.\.(\d+)\)", c)
    if m:
        k = int(m.group(1))
        return {"laplacianSpectrum()": [0.0] + [1.0] * (k - 1) + [k + 1.0],
                "adjacencySpectrum()": [-math.sqrt(k)] + [0.0] * (k - 1) + [math.sqrt(k)],
                "normalizedLaplacianSpectrum()": [0.0] + [1.0] * (k - 1) + [2.0]}.get(op)
    m = re.fullmatch(r"KB\(0\.\.(\d+);(\d+)\.\.(\d+)\)", c)
    if m:
        a = int(m.group(1)) + 1
        b = int(m.group(3)) - int(m.group(2)) + 1
        return {"laplacianSpectrum()": sorted([0.0] + [b] * (a - 1) + [a] * (b - 1) + [a + b]),
                "adjacencySpectrum()": sorted([-math.sqrt(a * b)] + [0.0] * (a + b - 2) + [math.sqrt(a * b)])}.get(op)
    m = re.fullmatch(r"Q\((\d+)\)", c)
    if m:
        d = int(m.group(1))
        lap = sorted(2.0 * k for k in range(d + 1) for _ in range(math.comb(d, k)))
        return {"laplacianSpectrum()": lap, "adjacencySpectrum()": sorted(d - x for x in lap),
                "normalizedLaplacianSpectrum()": [x / d for x in lap]}.get(op)
    m = re.fullmatch(r"grid\((\d+),(\d+)\)", c)
    if m:
        r, cc = int(m.group(1)), int(m.group(2))
        pr = [2 - 2 * math.cos(math.pi * k / r) for k in range(r)]
        pc = [2 - 2 * math.cos(math.pi * k / cc) for k in range(cc)]
        return {"laplacianSpectrum()": sorted(a + b for a in pr for b in pc)}.get(op)
    if c == "nx(petersen)":
        return {"laplacianSpectrum()": [0.0] + [2.0] * 5 + [5.0] * 4,
                "adjacencySpectrum()": [-2.0] * 4 + [1.0] * 5 + [3.0]}.get(op)
    return None


# ============================================================================ formatting

def fnum(x):
    if isinstance(x, Fraction):
        if x.denominator == 1:
            v = x.numerator
            if abs(v) > 2 ** 53:
                return f"{v} (≈ {float(v):.10g})"
            return str(v)
        return f"{x.numerator}/{x.denominator} ({float(x):.10g})"
    if abs(x) < 5e-11:
        return "0"
    s = f"{x:.10g}"
    r = float(s)
    if r == int(r) and abs(r) < 1e15:
        return str(int(r))
    return s


def fmat(M):
    if isinstance(M, list) and M and isinstance(M[0][0], Fraction):
        M = [[x for x in row] for row in M]
    n = len(M)
    if n == 0:
        return "0×0"
    nnz = sum(1 for row in M for x in row if (abs(float(x)) > 1e-15))
    if n <= 8:
        return "[" + ", ".join("[" + ", ".join(fnum(x) for x in row) + "]" for row in M) + "]" + f" (nnz {nnz})"
    tr = sum(float(M[i][i]) for i in range(n))
    sq = sum(float(x) ** 2 for row in M for x in row)
    tot = sum(float(x) for row in M for x in row)
    return f"{n}×{n}, nnz {nnz}, trace {fnum(tr)}, Σ entries {fnum(tot)}, Σ entries² {fnum(sq)}"


def group(vals):
    s = scale_of(vals)
    out = []
    for x in vals:
        if out and abs(x - out[-1][0]) <= 1e-8 * s:
            out[-1][1] += 1
        else:
            out.append([x, 1])
    return out


def fspec(vals):
    if not vals:
        return "[]"
    if len(vals) <= 30:
        return ", ".join(fnum(x) + (f" ×{k}" if k > 1 else "") for x, k in group(vals))
    head = ", ".join(fnum(x) for x in vals[:4])
    tail = ", ".join(fnum(x) for x in vals[-2:])
    return (f"{len(vals)} values; smallest {head}; largest {tail}; Σ {fnum(sum(vals))}; "
            f"Σ² {fnum(sum(x * x for x in vals))}")


def fvec(x):
    if len(x) <= 16:
        return "[" + ", ".join(fnum(t) for t in x) + "]"
    return "first 4 [" + ", ".join(fnum(t) for t in x[:4]) + f"], argmax {max(range(len(x)), key=lambda i: x[i])}, argmin {min(range(len(x)), key=lambda i: x[i])}"


# ============================================================================ NetworkX / SciPy cross-checks

def to_nx(g, w, simple=False):
    if g.directed:
        h = nx.DiGraph() if simple else nx.MultiDiGraph()
    else:
        h = nx.Graph() if simple else nx.MultiGraph()
    h.add_nodes_from(range(g.n))
    for (u, v), x in zip(g.edges, w):
        h.add_edge(u, v, weight=float(x))
    return h


def close(a, b, s, tol=1e-7):
    return abs(a - b) <= tol * s


def vclose(a, b, tol=1e-7):
    s = scale_of(list(a) + list(b))
    return len(a) == len(b) and all(abs(x - y) <= tol * s for x, y in zip(a, b))


def disagree(lib, why):
    DISAGREE[(lib, why)] += 1


def nx_matrix(g, w, kind):
    h = to_nx(g, w)
    if kind == "adjacencyMatrix":
        return nx.adjacency_matrix(h, nodelist=range(g.n)).toarray().astype(float)
    if kind == "laplacianMatrix":
        return nx.laplacian_matrix(h, nodelist=range(g.n)).toarray().astype(float)
    if kind == "normalizedLaplacianMatrix":
        return nx.normalized_laplacian_matrix(h, nodelist=range(g.n)).toarray().astype(float)
    return None


def cross_check(g, w, op, value):
    """Compare one computed value with NetworkX / SciPy / oracles; record disagreements."""
    name = op.split("(")[0]
    loops = g.has_loops()
    if name in ("adjacencyMatrix", "laplacianMatrix", "normalizedLaplacianMatrix") and g.n > 0:
        theirs = nx_matrix(g, w, name)
        ours = np.array(value, dtype=float)
        if not np.allclose(ours, theirs, atol=1e-9):
            assert loops, (op, ours, theirs)
            disagree("NetworkX", f"{name}: an undirected self-loop counts 1 in A[v][v] and in the degree (ours 2)")
        if name == "laplacianMatrix" and not g.directed and g.n > 0:
            sc = sp.sparse.csgraph.laplacian(np.array(adjacency(g, w), dtype=float))
            assert np.allclose(sc, ours), op
        if name == "normalizedLaplacianMatrix" and not g.directed and g.n > 0:
            sc = sp.sparse.csgraph.laplacian(np.array(adjacency(g, w), dtype=float), normed=True)
            if not np.allclose(sc, ours, atol=1e-9):
                disagree("SciPy", "csgraph.laplacian(normed=True) ignores the diagonal of A, so self-loops leave the degrees")
    elif name in ("laplacianSpectrum", "adjacencySpectrum", "normalizedLaplacianSpectrum") and g.n > 0:
        h = to_nx(g, w)
        if name == "laplacianSpectrum":
            theirs = sorted(nx.laplacian_spectrum(h))
        elif name == "normalizedLaplacianSpectrum":
            theirs = sorted(nx.normalized_laplacian_spectrum(h))
        else:
            theirs = sorted(np.real(nx.adjacency_spectrum(h)))
        if not vclose(value, theirs, 1e-8):
            assert loops, op
            disagree("NetworkX", f"{name}: self-loops counted once")
    elif name == "algebraicConnectivity" and not isinstance(value, str):
        norm = "normalized" in op
        h = to_nx(g, w)
        for method in METHODS:
            try:
                theirs = nx.algebraic_connectivity(h, normalized=norm, tol=1e-10, method=method, seed=1)
            except Exception:
                continue
            if not close(value, theirs, scale_of([value, theirs]), 1e-6):
                if norm and loops:
                    disagree("NetworkX", "algebraic_connectivity(normalized=True) drops self-loops from the degrees")
                    break
                assert method == "lanczos" and theirs > value, (op, method, value, theirs)
                disagree("NetworkX", "algebraic_connectivity(method='lanczos') returns λ₃ when λ₂ is multiple")
    elif name == "fiedlerVector" and value is not None and value[0] != "degenerate":
        norm = "normalized" in op
        h = to_nx(g, w)
        theirs = canonical_sign(list(nx.fiedler_vector(h, normalized=norm, tol=1e-12, method="tracemin_lu", seed=1)))
        if g.n == 2:
            assert [abs(t) for t in theirs] == [1.0, 1.0]
            disagree("NetworkX", "fiedler_vector on two vertices returns [1, -1], not a unit vector")
            theirs = [t / math.sqrt(2) for t in theirs]
        if not vclose(value[1], theirs, 1e-5):
            assert norm and loops, (op, g.n, g.edges, [float(x) for x in w], value, theirs)
            disagree("NetworkX", "fiedler_vector(normalized=True) drops self-loops from the degrees")
    elif name == "spectralOrdering" and g.n > 0:
        order, tied = value
        theirs = nx.spectral_ordering(to_nx(g, w), seed=1, tol=1e-12, method="tracemin_lu")
        if not tied:
            pos = 0
            for comp in components(g, w):
                seg, mine = theirs[pos:pos + len(comp)], order[pos:pos + len(comp)]
                assert seg == mine or seg == mine[::-1], (op, theirs, order)
                pos += len(comp)
    elif name == "numberOfSpanningTrees" and g.n > 0 and "root" not in op:
        theirs = nx.number_of_spanning_trees(to_nx(g, w), weight="weight")
        assert close(float(value), float(theirs), max(1.0, float(value)), 1e-8), (op, value, theirs)
    elif name == "resistanceDistance":
        a, b = map(int, re.findall(r"-?\d+", op)[:2])
        u, v = g.vertices.index(a), g.vertices.index(b)
        try:
            theirs = nx.resistance_distance(to_nx(g, w), u, v, weight="weight", invert_weight=False)
        except Exception:
            theirs = None
        if value is None or theirs is None:
            if value != theirs:
                disagree("NetworkX", "resistance_distance raises across components (ours nil)")
        else:
            assert close(float(value), theirs, max(1.0, float(value)), 1e-8), (op, value, theirs)
            L = np.array(laplacian(g, w), dtype=float)
            P = np.linalg.pinv(L)
            assert close(float(value), P[u, u] + P[v, v] - 2 * P[u, v], max(1.0, float(value)), 1e-8)
    elif name == "effectiveGraphResistance" and g.n > 0:
        theirs = nx.effective_graph_resistance(to_nx(g, w), weight="weight", invert_weight=False)
        if value is None:
            assert theirs == math.inf
            disagree("NetworkX", "effective_graph_resistance returns inf when disconnected (ours nil)")
        else:
            assert close(float(value), theirs, max(1.0, float(value)), 1e-8), (op, value, theirs)
    elif name == "kemenyConstant" and g.n > 0:
        try:
            theirs = nx.kemeny_constant(to_nx(g, w, simple=g.is_simple()), weight="weight")
        except Exception:
            theirs = None
        if value is None or theirs is None:
            if value != theirs:
                disagree("NetworkX", "kemeny_constant raises when disconnected (ours nil)")
        elif not close(value, theirs, max(1.0, value), 1e-8):
            assert loops or not g.is_simple(), (op, value, theirs)
            disagree("NetworkX", "kemeny_constant: self-loops counted once")
    elif name == "spectralRadius" and g.n > 2 and g.m > 0 and not loops:
        A = sp.sparse.csr_array(np.array(adjacency(g, w), dtype=float))
        theirs = sp.sparse.linalg.eigsh(A, k=1, which="LA", tol=1e-12)[0][0]
        assert close(value, theirs, max(1.0, value), 1e-8), (op, value, theirs)


# ============================================================================ evaluation

def parse_weights(op):
    m = re.search(r"\[(.*)\]\s*$", op)
    if not m or "weight:" not in op:
        return None
    out = []
    for t in m.group(1).split(","):
        t = t.strip()
        if t == "nan":
            out.append(float("nan"))
        elif t == "inf":
            out.append(float("inf"))
        elif re.fullmatch(r"-?\d+", t):
            out.append(int(t))
        else:
            out.append(float(t))
    return out


def evaluate(cell, op):
    g = parse_graph(cell)
    wr = parse_weights(op)
    call = op.split(" [")[0].strip()
    name = call.split("(")[0]
    try:
        w = check_weights(g, wr, allow_negative=(name == "adjacencyMatrix"))
        if name == "adjacencyMatrix":
            v = adjacency(g, w)
        elif name == "laplacianMatrix":
            if g.directed:
                A = adjacency(g, w)
                d = degrees(A)
                v = [[(d[i] if i == j else 0) - A[i][j] for j in range(g.n)] for i in range(g.n)]
            else:
                v = laplacian(g, w)
        elif name == "normalizedLaplacianMatrix":
            v = normalized(g, w)
        elif name == "randomWalkLaplacianMatrix":
            v = random_walk(g, w)
        elif name == "signlessLaplacianMatrix":
            v = signless(g, w)
        elif name == "laplacianSpectrum":
            v = eigvalsh(laplacian(g, w))
        elif name == "adjacencySpectrum":
            v = eigvalsh(adjacency(g, w))
        elif name == "normalizedLaplacianSpectrum":
            v = eigvalsh(normalized(g, w))
        elif name == "signlessLaplacianSpectrum":
            v = eigvalsh(signless(g, w))
        elif name == "algebraicConnectivity":
            v = lam2(g, w, "normalized" in call)
        elif name == "fiedlerVector":
            v = fiedler(g, w, "normalized" in call)
        elif name == "spectralOrdering":
            v = spectral_ordering(g, w, "normalized" in call)
        elif name == "spectralRadius":
            v = spectral_radius(g, w)
        elif name == "numberOfSpanningTrees":
            if "root" in call:
                r = int(re.search(r"root: (-?\d+)", call).group(1))
                if r not in g.vertices:
                    raise Trap("root not a vertex")
                v = arborescences(g, w, g.vertices.index(r))
            else:
                v = spanning_trees(g, w)
        elif name == "resistanceDistance":
            a, b = map(int, re.findall(r"-?\d+", call)[:2])
            if a not in g.vertices or b not in g.vertices:
                raise Trap("not a vertex")
            v = resistance(g, w, g.vertices.index(a), g.vertices.index(b))
        elif name == "effectiveGraphResistance":
            v = effective_graph_resistance(g, w) if g.n > 0 else Fraction(0)
        elif name == "kemenyConstant":
            v = kemeny(g, w)
        elif name == "spectralBisection":
            v = bisection(g, w)
        else:
            raise AssertionError(op)
    except Trap:
        return "**trap**"

    # oracles
    cf = closed_form(cell, call)
    if cf is not None:
        assert vclose(v, cf, 1e-9), (cell, op, v, cf)
    if name == "numberOfSpanningTrees" and g.m <= 16:
        if "root" in call:
            assert v == brute_arborescences(g, w, g.vertices.index(int(re.search(r"root: (-?\d+)", call).group(1)))), op
        else:
            assert v == brute_spanning_trees(g, w), (cell, op)
    if name == "effectiveGraphResistance" and v is not None and g.n > 1:
        lam = eigvalsh(laplacian(g, w))
        assert close(float(v), g.n * sum(1 / x for x in lam[1:]), max(1.0, float(v)), 1e-9)
    if name in ("laplacianSpectrum", "adjacencySpectrum", "normalizedLaplacianSpectrum", "signlessLaplacianSpectrum") and g.n:
        M = {"laplacianSpectrum": laplacian, "adjacencySpectrum": adjacency,
             "normalizedLaplacianSpectrum": normalized, "signlessLaplacianSpectrum": signless}[name](g, w)
        assert close(sum(v), sum(float(M[i][i]) for i in range(g.n)), scale_of(v) * g.n, 1e-9)
    if name == "fiedlerVector" and v is not None and v[0] != "degenerate":
        M = np.array(normalized(g, w) if "normalized" in call else laplacian(g, w), dtype=float)
        x = np.array(v[1])
        assert np.linalg.norm(M @ x - v[0] * x) <= 1e-9 * scale_of([v[0], float(np.abs(M).max())])
    if not g.directed or name in ("adjacencyMatrix", "laplacianMatrix"):
        if not g.directed:
            cross_check(g, w, call, v)
        elif g.n > 0:
            ours = np.array(v, dtype=float)
            theirs = nx_matrix(g, w, name)
            assert np.allclose(ours, theirs), (op, ours, theirs)
    if name == "numberOfSpanningTrees" and g.directed and g.n > 0:
        r = int(re.search(r"root: (-?\d+)", call).group(1))
        theirs = nx.number_of_spanning_trees(to_nx(g, w), root=g.vertices.index(r), weight="weight")
        assert close(float(v), float(theirs), max(1.0, float(v)), 1e-8), (op, v, theirs)
    if name == "spectralBisection" and v is not None and v[0] != "degenerate":
        a, b = nx.spectral_bisection(to_nx(g, w, simple=True), seed=1, tol=1e-12, method="tracemin_lu")
        if {frozenset(a), frozenset(b)} != {frozenset(g.vertices.index(x) for x in v[0]), frozenset(g.vertices.index(x) for x in v[1])}:
            x = fiedler(g, w, False)[1]
            assert min(abs(t) for t in x) <= 1e-8 * max(abs(t) for t in x), op
            disagree("NetworkX", "spectral_bisection: a zero Fiedler entry goes by its rounding sign (ours: the nonnegative side)")

    return render_value(name, g, v)


def render_value(name, g, v):
    if name.endswith("Matrix"):
        return fmat(v)
    if name.endswith("Spectrum"):
        return fspec(v)
    if name == "fiedlerVector":
        if v is None:
            return "nil"
        if v[0] == "degenerate":
            return f"degenerate: λ₂ = {fnum(v[1])} ×{v[2]} (some unit vector of that eigenspace)"
        return f"λ₂ = {fnum(v[0])}; {fvec(v[1])}"
    if name == "spectralOrdering":
        order, tied = v
        s = "[" + ", ".join(str(g.vertices[i]) for i in order) + "]"
        return s + (" (ties: index order within tolerance)" if tied else "")
    if name == "spectralBisection":
        if v is None:
            return "nil"
        if v[0] == "degenerate":
            return "degenerate λ₂: some split by a λ₂ eigenvector"
        return f"([{', '.join(map(str, v[0]))}], [{', '.join(map(str, v[1]))}])"
    if v is None:
        return "nil"
    return fnum(v)


# ============================================================================ the rows

ROWS = []


def R(group_, case, cell, op):
    ROWS.append([None, group_, case, cell, op, None])


def define():
    M = "Matrices"
    R(M, "empty graph", "U:", "laplacianMatrix()")
    R(M, "one vertex: a 1×1 zero matrix, no stored entries", "U: [0]", "laplacianMatrix()")
    for op in ("adjacencyMatrix()", "laplacianMatrix()", "normalizedLaplacianMatrix()", "randomWalkLaplacianMatrix()", "signlessLaplacianMatrix()"):
        R(M, "path on 3 vertices", "U: P(0,1,2)", op)
    R(M, "K4 Laplacian", "U: K(4)", "laplacianMatrix()")
    R(M, "K4 normalized Laplacian", "U: K(4)", "normalizedLaplacianMatrix()")
    R(M, "star K1,3 normalized Laplacian", "U: S(0;1..3)", "normalizedLaplacianMatrix()")
    R(M, "rows follow `vertices` order, not vertex values", "U: [2,0,1] 2-0, 0-1", "laplacianMatrix()")
    R(M, "rows follow `vertices` order: adjacency", "U: [2,0,1] 2-0, 0-1", "adjacencyMatrix()")
    for op in ("adjacencyMatrix()", "laplacianMatrix()", "normalizedLaplacianMatrix()"):
        R(M, "parallel edges add up", "U: 0=1, 1-2", op)
    for op in ("adjacencyMatrix()", "laplacianMatrix()", "normalizedLaplacianMatrix()", "randomWalkLaplacianMatrix()", "signlessLaplacianMatrix()"):
        R(M, "self-loop: 2 on the diagonal of A, cancels in L", "U: 0-0, 0-1", op)
    R(M, "bouquet of two loops: A = [[4]], L = 0", "U: 0-0, 0-0", "adjacencyMatrix()")
    R(M, "bouquet of two loops: normalized Laplacian is 0", "U: 0-0, 0-0", "normalizedLaplacianMatrix()")
    R(M, "isolated vertex: zero row in the normalized Laplacian", "U: [0,1,2] 0-1", "normalizedLaplacianMatrix()")
    R(M, "isolated vertex: zero row in the random-walk Laplacian", "U: [0,1,2] 0-1", "randomWalkLaplacianMatrix()")
    for op in ("adjacencyMatrix(weight:) [2, 0.5]", "laplacianMatrix(weight:) [2, 0.5]", "normalizedLaplacianMatrix(weight:) [2, 0.5]", "randomWalkLaplacianMatrix(weight:) [2, 0.5]"):
        R(M, "weighted path", "U: P(0,1,2)", op)
    R(M, "weight 0: no stored entry", "U: P(0,1,2)", "laplacianMatrix(weight:) [1, 0]")
    R(M, "parallel weights add up", "U: 0=1", "laplacianMatrix(weight:) [1.5, 2.5]")
    R(M, "adjacency allows negative weights", "U: P(0,1,2)", "adjacencyMatrix(weight:) [-1, 2]")
    R(M, "Laplacian: negative weight", "U: P(0,1,2)", "laplacianMatrix(weight:) [-1, 2]")
    R(M, "Laplacian: NaN weight", "U: P(0,1,2)", "laplacianMatrix(weight:) [nan, 2]")
    R(M, "Laplacian: infinite weight", "U: P(0,1,2)", "laplacianMatrix(weight:) [inf, 2]")
    R(M, "adjacency: NaN weight", "U: P(0,1,2)", "adjacencyMatrix(weight:) [nan, 2]")
    R(M, "grid 10×10 Laplacian (invariants)", "U: grid(10,10)", "laplacianMatrix()")
    R(M, "hypercube Q4 normalized Laplacian (invariants)", "U: Q(4)", "normalizedLaplacianMatrix()")
    R(M, "Petersen adjacency (invariants)", "U: nx(petersen)", "adjacencyMatrix()")
    R(M, "karate club Laplacian (invariants)", "U: nx(karate_club)", "laplacianMatrix()")
    R(M, "directed 3-cycle adjacency", "D: C(0,1,2)", "adjacencyMatrix()")
    R(M, "directed Laplacian: out-degrees", "D: 0>1, 0>2, 1>2", "laplacianMatrix()")
    R(M, "directed self-loop: 1 on the diagonal, cancels in L", "D: 0>0, 0>1", "adjacencyMatrix()")
    R(M, "directed self-loop cancels in the Laplacian", "D: 0>0, 0>1", "laplacianMatrix()")
    R(M, "directed parallel arcs add up", "D: 0>1, 0>1, 1>0", "adjacencyMatrix()")
    R(M, "directed weighted Laplacian", "D: 0>1, 1>2, 2>0, 0>2", "laplacianMatrix(weight:) [1, 2, 3, 4]")
    R(M, "directed isolated vertex", "D: [0,1,2] 0>1", "laplacianMatrix()")

    S = "Spectra"
    R(S, "empty graph", "U:", "laplacianSpectrum()")
    R(S, "one vertex", "U: [0]", "laplacianSpectrum()")
    R(S, "three isolated vertices", "U: E(3)", "laplacianSpectrum()")
    R(S, "K2", "U: K(2)", "laplacianSpectrum()")
    for op in ("laplacianSpectrum()", "adjacencySpectrum()", "normalizedLaplacianSpectrum()"):
        R(S, "K5", "U: K(5)", op)
        R(S, "path P5", "U: P(0..4)", op)
        R(S, "cycle C6", "U: C(0..5)", op)
        R(S, "star K1,4", "U: S(0;1..4)", op)
        R(S, "hypercube Q3", "U: Q(3)", op)
    R(S, "K2,3 Laplacian", "U: KB(0..1;2..4)", "laplacianSpectrum()")
    R(S, "K2,3 adjacency", "U: KB(0..1;2..4)", "adjacencySpectrum()")
    R(S, "Petersen Laplacian", "U: nx(petersen)", "laplacianSpectrum()")
    R(S, "Petersen adjacency", "U: nx(petersen)", "adjacencySpectrum()")
    R(S, "grid 3×4 Laplacian", "U: grid(3,4)", "laplacianSpectrum()")
    R(S, "two triangles: 0 twice", "U: C(0,1,2), C(3,4,5)", "laplacianSpectrum()")
    R(S, "path and isolated vertex, normalized: 0 per component", "U: [0,1,2,3] P(0,1,2)", "normalizedLaplacianSpectrum()")
    R(S, "doubled edge", "U: 0=1", "laplacianSpectrum()")
    R(S, "self-loop: adjacency 1 ± √2", "U: 0-0, 0-1", "adjacencySpectrum()")
    R(S, "self-loop: Laplacian unchanged", "U: 0-0, 0-1", "laplacianSpectrum()")
    R(S, "self-loop: normalized", "U: 0-0, 0-1", "normalizedLaplacianSpectrum()")
    R(S, "weighted triangle", "U: C(0,1,2)", "laplacianSpectrum(weight:) [1, 2, 3]")
    R(S, "weighted triangle, normalized", "U: C(0,1,2)", "normalizedLaplacianSpectrum(weight:) [1, 2, 3]")
    R(S, "grid 20×20 Laplacian (summary)", "U: grid(20,20)", "laplacianSpectrum()")
    R(S, "hypercube Q6 Laplacian (summary)", "U: Q(6)", "laplacianSpectrum()")
    R(S, "karate club Laplacian (summary)", "U: nx(karate_club)", "laplacianSpectrum()")
    R(S, "karate club adjacency (summary)", "U: nx(karate_club)", "adjacencySpectrum()")
    R(S, "random multigraph lcg(60,150,3) normalized (summary)", "U: lcg(60,150,3)", "normalizedLaplacianSpectrum()")
    R(S, "negative weight", "U: P(0,1,2)", "laplacianSpectrum(weight:) [-1, 1]")

    A = "Algebraic connectivity"
    R(A, "K2", "U: K(2)", "algebraicConnectivity()")
    R(A, "path P10: 2 − 2cos(π/10)", "U: P(0..9)", "algebraicConnectivity()")
    R(A, "cycle C10: 2 − 2cos(2π/10)", "U: C(0..9)", "algebraicConnectivity()")
    R(A, "K6", "U: K(6)", "algebraicConnectivity()")
    R(A, "star K1,5", "U: S(0;1..5)", "algebraicConnectivity()")
    R(A, "hypercube Q4", "U: Q(4)", "algebraicConnectivity()")
    R(A, "Petersen", "U: nx(petersen)", "algebraicConnectivity()")
    R(A, "grid 10×10", "U: grid(10,10)", "algebraicConnectivity()")
    R(A, "grid 30×30", "U: grid(30,30)", "algebraicConnectivity()")
    R(A, "karate club", "U: nx(karate_club)", "algebraicConnectivity()")
    R(A, "disconnected: 0", "U: C(0,1,2), C(3,4,5)", "algebraicConnectivity()")
    R(A, "two isolated vertices: 0", "U: E(2)", "algebraicConnectivity()")
    R(A, "doubled edge: 4", "U: 0=1", "algebraicConnectivity()")
    R(A, "loops do not change L", "U: 0-0, P(0..3)", "algebraicConnectivity()")
    R(A, "weighted path", "U: P(0..3)", "algebraicConnectivity(weight:) [1, 2, 3]")
    R(A, "weight 0 disconnects", "U: P(0..3)", "algebraicConnectivity(weight:) [1, 0, 1]")
    R(A, "path P10, normalized: 1 − cos(π/9)", "U: P(0..9)", "algebraicConnectivity(normalized: true)")
    R(A, "Petersen, normalized", "U: nx(petersen)", "algebraicConnectivity(normalized: true)")
    R(A, "karate club, normalized", "U: nx(karate_club)", "algebraicConnectivity(normalized: true)")
    R(A, "self-loop, normalized: loops count in the degrees", "U: 0-0, P(0..3)", "algebraicConnectivity(normalized: true)")
    R(A, "lcg(200,600,11)", "U: lcg(200,600,11)", "algebraicConnectivity()")
    R(A, "one vertex", "U: [0]", "algebraicConnectivity()")
    R(A, "empty graph", "U:", "algebraicConnectivity()")

    F = "Fiedler vector"
    R(F, "path P4", "U: P(0..3)", "fiedlerVector()")
    R(F, "path P5: middle entry 0", "U: P(0..4)", "fiedlerVector()")
    R(F, "path P4 in another vertex order", "U: P(2,0,3,1)", "fiedlerVector()")
    R(F, "canonical sign: the first significant entry is positive", "U: P(3,2,1,0)", "fiedlerVector()")
    R(F, "barbell: two K4 joined by an edge", "U: K(0..3), K(4..7), 3-4", "fiedlerVector()")
    R(F, "grid 3×4", "U: grid(3,4)", "fiedlerVector()")
    R(F, "weighted path", "U: P(0..3)", "fiedlerVector(weight:) [1, 2, 3]")
    R(F, "parallel edge counts twice", "U: 0=1, P(1,2,3)", "fiedlerVector()")
    R(F, "loop does not change it", "U: 1-1, P(0..3)", "fiedlerVector()")
    R(F, "path P4 normalized", "U: P(0..3)", "fiedlerVector(normalized: true)")
    R(F, "karate club", "U: nx(karate_club)", "fiedlerVector()")
    R(F, "K4: λ₂ = 4 ×3", "U: K(4)", "fiedlerVector()")
    R(F, "cycle C6: λ₂ = 1 ×2", "U: C(0..5)", "fiedlerVector()")
    R(F, "star K1,4: λ₂ = 1 ×3", "U: S(0;1..4)", "fiedlerVector()")
    R(F, "hypercube Q3", "U: Q(3)", "fiedlerVector()")
    R(F, "disconnected", "U: C(0,1,2), C(3,4,5)", "fiedlerVector()")
    R(F, "two isolated vertices", "U: E(2)", "fiedlerVector()")
    R(F, "weight 0 disconnects", "U: P(0..3)", "fiedlerVector(weight:) [1, 0, 1]")
    R(F, "one vertex", "U: [0]", "fiedlerVector()")

    O = "Spectral ordering"
    R(O, "path in shuffled order", "U: P(2,0,4,1,3)", "spectralOrdering()")
    R(O, "barbell", "U: K(0..3), K(4..7), 3-4", "spectralOrdering()")
    R(O, "components by least vertex; small ones in index order", "U: [0,1,2,3,4,5,6,7] P(5,1,6), 3-4, P(0,7,2)", "spectralOrdering()")
    R(O, "grid 2×5: tied entries in index order", "U: grid(2,5)", "spectralOrdering()")
    R(O, "weighted path", "U: P(0..4)", "spectralOrdering(weight:) [1, 3, 1, 3]")
    R(O, "karate club", "U: nx(karate_club)", "spectralOrdering()")
    R(O, "one vertex", "U: [0]", "spectralOrdering()")
    R(O, "empty graph", "U:", "spectralOrdering()")

    Z = "Spectral radius"
    R(Z, "K5: 4", "U: K(5)", "spectralRadius()")
    R(Z, "path P5: √3", "U: P(0..4)", "spectralRadius()")
    R(Z, "cycle C7: 2", "U: C(0..6)", "spectralRadius()")
    R(Z, "star K1,4: 2", "U: S(0;1..4)", "spectralRadius()")
    R(Z, "Petersen: 3", "U: nx(petersen)", "spectralRadius()")
    R(Z, "grid 10×10: 4cos(π/11)", "U: grid(10,10)", "spectralRadius()")
    R(Z, "karate club", "U: nx(karate_club)", "spectralRadius()")
    R(Z, "doubled edge: 2", "U: 0=1", "spectralRadius()")
    R(Z, "self-loop: 1 + √2", "U: 0-0, 0-1", "spectralRadius()")
    R(Z, "weighted", "U: C(0,1,2)", "spectralRadius(weight:) [1, 2, 3]")
    R(Z, "isolated vertices: 0", "U: E(3)", "spectralRadius()")
    R(Z, "empty graph: 0", "U:", "spectralRadius()")
    R(Z, "lcg(200,600,11)", "U: lcg(200,600,11)", "spectralRadius()")

    T = "Spanning trees"
    R(T, "empty graph: 0", "U:", "numberOfSpanningTrees()")
    R(T, "one vertex: 1", "U: [0]", "numberOfSpanningTrees()")
    R(T, "two isolated vertices: 0", "U: E(2)", "numberOfSpanningTrees()")
    R(T, "K2", "U: K(2)", "numberOfSpanningTrees()")
    R(T, "K5: 5³", "U: K(5)", "numberOfSpanningTrees()")
    R(T, "K10: 10⁸", "U: K(10)", "numberOfSpanningTrees()")
    R(T, "K25: 25²³, past 2⁵³", "U: K(25)", "numberOfSpanningTrees()")
    R(T, "cycle C6", "U: C(0..5)", "numberOfSpanningTrees()")
    R(T, "path P6", "U: P(0..5)", "numberOfSpanningTrees()")
    R(T, "K3,3: 3²·3²", "U: KB(0..2;3..5)", "numberOfSpanningTrees()")
    R(T, "Petersen: 2000", "U: nx(petersen)", "numberOfSpanningTrees()")
    R(T, "hypercube Q3: 384", "U: Q(3)", "numberOfSpanningTrees()")
    R(T, "hypercube Q4", "U: Q(4)", "numberOfSpanningTrees()")
    R(T, "grid 3×3: 192", "U: grid(3,3)", "numberOfSpanningTrees()")
    R(T, "grid 8×8", "U: grid(8,8)", "numberOfSpanningTrees()")
    R(T, "doubled edge and pendant: 2", "U: 0=1, 1-2", "numberOfSpanningTrees()")
    R(T, "loop ignored", "U: 0-0, C(0,1,2)", "numberOfSpanningTrees()")
    R(T, "weighted triangle: 1·2 + 2·3 + 1·3", "U: C(0,1,2)", "numberOfSpanningTrees(weight:) [1, 2, 3]")
    R(T, "weighted, fractional", "U: K(4)", "numberOfSpanningTrees(weight:) [0.5, 1, 2, 1, 0.25, 3]")
    R(T, "disconnected: 0", "U: C(0,1,2), C(3,4,5)", "numberOfSpanningTrees()")
    R(T, "karate club", "U: nx(karate_club)", "numberOfSpanningTrees()")

    D = "Resistance distance"
    R(D, "path: series", "U: P(0..3)", "resistanceDistance(from: 0, to: 3)")
    R(D, "cycle C4: two paths of 2 in parallel", "U: C(0..3)", "resistanceDistance(from: 0, to: 2)")
    R(D, "K4: 2/n", "U: K(4)", "resistanceDistance(from: 1, to: 2)")
    R(D, "same vertex: 0", "U: K(4)", "resistanceDistance(from: 2, to: 2)")
    R(D, "different components: nil", "U: C(0,1,2), C(3,4,5)", "resistanceDistance(from: 0, to: 4)")
    R(D, "isolated vertex to itself: 0", "U: [0,1] ", "resistanceDistance(from: 1, to: 1)")
    R(D, "doubled edge: 1/2", "U: 0=1", "resistanceDistance(from: 0, to: 1)")
    R(D, "weights are conductances", "U: P(0..2)", "resistanceDistance(from: 0, to: 2) weight: [2, 4]")
    R(D, "Wheatstone bridge", "U: 0-1, 0-2, 1-2, 1-3, 2-3", "resistanceDistance(from: 0, to: 3)")
    R(D, "Petersen, adjacent", "U: nx(petersen)", "resistanceDistance(from: 0, to: 1)")
    R(D, "Petersen, at distance 2", "U: nx(petersen)", "resistanceDistance(from: 0, to: 2)")
    R(D, "grid 3×3 corners", "U: grid(3,3)", "resistanceDistance(from: 0, to: 8)")
    R(D, "loop ignored", "U: 1-1, P(0..2)", "resistanceDistance(from: 0, to: 2)")
    R(D, "weight 0 disconnects: nil", "U: P(0..2)", "resistanceDistance(from: 0, to: 2) weight: [1, 0]")
    R(D, "not a vertex", "U: P(0..2)", "resistanceDistance(from: 0, to: 9)")
    R(D, "negative weight", "U: P(0..2)", "resistanceDistance(from: 0, to: 2) weight: [1, -1]")

    E = "Effective graph resistance"
    R(E, "empty graph: 0", "U:", "effectiveGraphResistance()")
    R(E, "one vertex: 0", "U: [0]", "effectiveGraphResistance()")
    R(E, "K5: n − 1", "U: K(5)", "effectiveGraphResistance()")
    R(E, "path P4: the Wiener index", "U: P(0..3)", "effectiveGraphResistance()")
    R(E, "cycle C6", "U: C(0..5)", "effectiveGraphResistance()")
    R(E, "Petersen", "U: nx(petersen)", "effectiveGraphResistance()")
    R(E, "weighted", "U: C(0,1,2)", "effectiveGraphResistance(weight:) [1, 2, 3]")
    R(E, "disconnected: nil", "U: C(0,1,2), C(3,4,5)", "effectiveGraphResistance()")
    R(E, "karate club", "U: nx(karate_club)", "effectiveGraphResistance()")

    K = "Kemeny constant"
    R(K, "empty graph: 0", "U:", "kemenyConstant()")
    R(K, "one vertex: 0", "U: [0]", "kemenyConstant()")
    R(K, "K2: 1/2", "U: K(2)", "kemenyConstant()")
    R(K, "K5", "U: K(5)", "kemenyConstant()")
    R(K, "path P4", "U: P(0..3)", "kemenyConstant()")
    R(K, "cycle C6", "U: C(0..5)", "kemenyConstant()")
    R(K, "star K1,4", "U: S(0;1..4)", "kemenyConstant()")
    R(K, "self-loop counts twice in the degree", "U: 0-0, P(0,1,2)", "kemenyConstant()")
    R(K, "weighted", "U: C(0,1,2)", "kemenyConstant(weight:) [1, 2, 3]")
    R(K, "disconnected: nil", "U: C(0,1,2), C(3,4,5)", "kemenyConstant()")
    R(K, "karate club", "U: nx(karate_club)", "kemenyConstant()")

    P = "Phase 2"
    R(P, "arborescences of a directed 3-cycle from 0", "D: C(0,1,2)", "numberOfSpanningTrees(root: 0)")
    R(P, "arborescences, both arcs of K3", "D: 0>1, 1>0, 0>2, 2>0, 1>2, 2>1", "numberOfSpanningTrees(root: 0)")
    R(P, "arborescences: root reaches nothing", "D: 1>0, 2>0", "numberOfSpanningTrees(root: 0)")
    R(P, "arborescences: weighted", "D: 0>1, 0>2, 1>2, 2>1", "numberOfSpanningTrees(root: 0) weight: [1, 2, 3, 4]")
    R(P, "arborescences: parallel arcs and a loop", "D: 0>1, 0>1, 1>1, 1>2", "numberOfSpanningTrees(root: 0)")
    R(P, "arborescences: root not a vertex", "D: C(0,1,2)", "numberOfSpanningTrees(root: 7)")
    R(P, "signless Laplacian of a bipartite graph = its Laplacian spectrum", "U: C(0..5)", "signlessLaplacianSpectrum()")
    R(P, "signless Laplacian of a triangle", "U: C(0,1,2)", "signlessLaplacianSpectrum()")
    R(P, "signless Laplacian with a loop: Q[v][v] gains 4", "U: 0-0, 0-1", "signlessLaplacianSpectrum()")
    R(P, "spectral bisection of the barbell", "U: K(0..3), K(4..7), 3-4", "spectralBisection()")
    R(P, "spectral bisection of P5: the zero entry joins the nonnegative side", "U: P(0..4)", "spectralBisection()")
    R(P, "spectral bisection, degenerate λ₂", "U: C(0..5)", "spectralBisection()")
    R(P, "spectral bisection, disconnected", "U: C(0,1,2), C(3,4,5)", "spectralBisection()")


def number_rows():
    for i, r in enumerate(ROWS):
        r[0] = f"SGT-{i + 1:03d}"


def compute():
    for r in ROWS:
        r[5] = evaluate(r[3], r[4])


def render():
    lines = [HEADER.format(last=len(ROWS), count=len(ROWS), p2=next(r[0] for r in ROWS if r[1] == "Phase 2"))]
    lines.append("| ID | Group | Case | Graph | Op | Expected |")
    lines.append("|---|---|---|---|---|---|")
    for r in ROWS:
        cells = [r[0], r[1], r[2], f"`{r[3]}`", f"`{r[4]}`", r[5]]
        lines.append("| " + " | ".join(c.replace("|", "\\|") for c in cells) + " |")
    lines.append("")
    lines.append(f"{len(ROWS)} rows.")
    return "\n".join(lines) + "\n"


HEADER = """# SpectralGraphTheory: case catalog (SGT-001 – SGT-{last:03d}, {count} rows; {p2} onward have no entry point)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
scipy==1.18.1 --with numpy==2.5.4 python3 Tests/Catalogs/SpectralGraphTheory/ref.py`; `--write`
regenerates this file, `--stress` adds random multigraphs). The model builds every matrix from the
definitions in api.md in exact fractions (floating point only for the normalized matrices),
takes spectra from `numpy.linalg.eigvalsh`, and counts spanning trees, resistances and effective
graph resistance exactly. Rows are also checked against closed forms (complete, path, cycle,
star, complete bipartite, hypercube, grid, Petersen spectra), brute-force spanning-tree and
arborescence enumeration (at most 16 edges), the Moore–Penrose pseudoinverse, NetworkX 3.7 and
SciPy 1.18.1; the known disagreements are counted in `ref.py`'s DISAGREE.

## Notation

**Graph**: `U:` undirected, `D:` directed. An optional vertex list in brackets comes first, then
edges in **position order**. `vertices` is the listed vertices, then the vertices of generators,
then endpoints by first appearance. Vertices are `Int`s; matrix rows and vector entries follow
`vertices` order.

| Token | Edges |
|---|---|
| `u-v`, `u>v`, `u=v` | one edge (`u-u` a self-loop); one arc; two parallel edges u–v |
| `P(a,b,…)`, `C(a,b,…,z)` | the path a–b, b–c, …; the cycle a–b, …, z–a (arcs in a `D:` graph) |
| `S(c;a..b)` | the star c–a, …, c–b |
| `K(n)`, `K(a..b)` | vertices listed, every pair i < j, lexicographic |
| `KB(a..b;c..d)` | each of the first list to each of the second, row-major |
| `E(n)` | vertices 0..<n, no edges |
| `grid(r,c)` | vertices `i*c + j` listed; for each vertex in order the edge right, then down |
| `Q(d)` | hypercube: vertices 0..<2^d listed; for i in order, for k = 0..<d, i–(i ^ 2^k) when i < i ^ 2^k |
| `nx(name)` | `networkx.<name>_graph()`: its `nodes` listed, then `edges()` in NetworkX's order |
| `lcg(n,m,s)` | vertices 0..<n, then m non-loop pairs from the 64-bit LCG of the Distances catalog, seeded s (parallel pairs possible) |
| `a..b` | every integer from a to b inclusive |

**Op** is the call on the graph. `(weight:) [w₀, w₁, …]` and `weight: […]` pass a weight closure
returning wₚ for the edge at position p (`nan`, `inf` are those `Double`s).

**Expected.**

- A matrix is its dense rows when n ≤ 8, with `nnz`, the number of stored entries (the nonzero
  ones: a `SparseMatrix` stores no zeros). For larger n: its invariants, `nnz`, the trace, the sum
  of all entries and the sum of their squares.
- A spectrum is ascending, each distinct value once with `×k` for its multiplicity. Above 30
  values: the count, the four smallest and two largest, the sum and the sum of squares.
- `fiedlerVector`: `λ₂ = …; [entries]` when λ₂ is simple, with the canonical sign (api.md); above
  16 vertices the first four entries and the indices of the largest and smallest entry.
  `degenerate: λ₂ = x ×k` means λ₂ has multiplicity k: the test checks only that the result is a
  unit vector orthogonal to the null vector with residual ‖Lx − λ₂x‖ within tolerance and
  Rayleigh quotient λ₂. `nil`: not connected.
- `spectralOrdering` lists vertices. `(ties: …)` marks rows whose order relies on the tie rule or
  a degenerate λ₂ (api.md): the test checks the order is sorted by the returned Fiedler values,
  not the exact list.
- Exact rationals are written `p/q (decimal)`; counts past 2⁵³ are written exactly with the
  `Double` that `numberOfSpanningTrees` returns.
- **Tolerances**: integers and rationals exact up to `Double` rounding (relative 1e-12); dense
  results (matrices, spectra, counts, effective graph resistance, Kemeny constant) within
  1e-9 · max(1, |largest value|); iterative results (`algebraicConnectivity`, `fiedlerVector`,
  `spectralOrdering`, `spectralRadius`, `resistanceDistance`) within 1e-6 · max(1, scale) for
  values and 1e-5 per vector entry. Decimals are printed to 10 significant digits.
- `**trap**` rows are preconditions.

"""


# ============================================================================ stress

def random_graph(rng, n, directed, loops, multi, m):
    es, seen = [], set()
    while len(es) < m:
        u, v = rng.randrange(n), rng.randrange(n)
        if u == v and not loops:
            continue
        k = (u, v) if directed else (min(u, v), max(u, v))
        if not multi and k in seen:
            continue
        seen.add(k)
        es.append((u, v))
    return G(directed, range(n), es)


def stress():
    import random
    rng = random.Random(20261011)
    c = Counter()
    for t in range(1000):
        n = rng.randint(1, 7)
        directed = t % 5 == 4
        loops, multi = rng.random() < 0.4, rng.random() < 0.5
        maxm = n * (n - 1) // (1 if directed else 2) + (n if loops else 0)
        m = rng.randint(0, min(12, maxm if not multi else 12))
        if maxm == 0 and not multi:
            m = 0
        if n == 1 and not loops:
            m = 0
        g = random_graph(rng, n, directed, loops, multi, m)
        weighted = rng.random() < 0.5
        w = [Fraction(rng.randint(1, 4), rng.choice([1, 2])) for _ in range(g.m)] if weighted else [Fraction(1)] * g.m
        if directed:
            r = rng.randrange(n)
            assert arborescences(g, w, r) == brute_arborescences(g, w, r)
            theirs = nx.number_of_spanning_trees(to_nx(g, w), root=r, weight="weight")
            assert close(float(arborescences(g, w, r)), theirs, max(1.0, theirs), 1e-8)
            for name in ("adjacencyMatrix", "laplacianMatrix"):
                ours = np.array(adjacency(g, w) if name == "adjacencyMatrix" else
                                [[(degrees(adjacency(g, w))[i] if i == j else 0) - adjacency(g, w)[i][j] for j in range(n)] for i in range(n)], dtype=float)
                assert np.allclose(ours, nx_matrix(g, w, name))
            c["directed"] += 1
            continue
        tau = spanning_trees(g, w)
        assert tau == brute_spanning_trees(g, w)
        c["spanning-tree counts"] += 1
        for name in ("adjacencyMatrix", "laplacianMatrix", "normalizedLaplacianMatrix"):
            v = {"adjacencyMatrix": adjacency, "laplacianMatrix": laplacian, "normalizedLaplacianMatrix": normalized}[name](g, w)
            cross_check(g, w, name + "()", v)
        for name in ("laplacianSpectrum", "normalizedLaplacianSpectrum", "adjacencySpectrum"):
            v = eigvalsh({"laplacianSpectrum": laplacian, "normalizedLaplacianSpectrum": normalized, "adjacencySpectrum": adjacency}[name](g, w))
            cross_check(g, w, name + "()", v)
        c["matrices and spectra"] += 1
        conn = len(components(g, w)) == 1
        if n >= 2:
            cross_check(g, w, "algebraicConnectivity()", lam2(g, w, False))
            cross_check(g, w, "algebraicConnectivity(normalized: true)", lam2(g, w, True))
            c["algebraic connectivity"] += 1
            f = fiedler(g, w, False)
            if f is not None and f[0] != "degenerate":
                cross_check(g, w, "fiedlerVector()", f)
                c["Fiedler vectors"] += 1
        if n >= 1:
            u, v = rng.randrange(n), rng.randrange(n)
            val = resistance(g, w, u, v)
            cross_check(g, w, f"resistanceDistance(from: {u}, to: {v})", val)
            c["resistances"] += 1
            egr = effective_graph_resistance(g, w)
            cross_check(g, w, "effectiveGraphResistance()", egr)
            if conn:
                cross_check(g, w, "kemenyConstant()", kemeny(g, w))
            o = spectral_ordering(g, w)
            cross_check(g, w, "spectralOrdering()", o)
            c["orderings"] += 1
    return c


# ============================================================================ bench

def bench():
    """Baselines for api.md: SciPy eigsh (ARPACK; igraph's eigen_adjacency is the same ARPACK)
    and NetworkX's algebraic_connectivity (TraceMIN-PCG), 120 s limit each."""

    class Timeout(Exception):
        pass

    def handler(signum, frame):
        raise Timeout()

    signal.signal(signal.SIGALRM, handler)

    def timed(f, limit=120):
        signal.alarm(limit)
        try:
            t = time.perf_counter()
            r = f()
            return (time.perf_counter() - t) * 1000, r
        except Timeout:
            return None, None
        finally:
            signal.alarm(0)

    def largest_cc(h):
        return nx.convert_node_labels_to_integers(h.subgraph(max(nx.connected_components(h), key=len)).copy())

    cases = [
        ("grid 100×100", lambda: nx.convert_node_labels_to_integers(nx.grid_2d_graph(100, 100))),
        ("grid 300×300", lambda: nx.convert_node_labels_to_integers(nx.grid_2d_graph(300, 300))),
        ("grid 1000×1000", lambda: nx.convert_node_labels_to_integers(nx.grid_2d_graph(1000, 1000))),
        ("random 3-regular, 10⁴", lambda: nx.random_regular_graph(3, 10_000, seed=1)),
        ("random 3-regular, 10⁵", lambda: nx.random_regular_graph(3, 100_000, seed=1)),
        ("G(n, p), n = 10⁴, mean degree 10 (giant component)", lambda: largest_cc(nx.fast_gnp_random_graph(10_000, 0.001, seed=1))),
        ("G(n, p), n = 10⁵, mean degree 10 (giant component)", lambda: largest_cc(nx.fast_gnp_random_graph(100_000, 0.0001, seed=1))),
    ]
    print("| Input | n | m | NetworkX laplacian_matrix | csgraph.laplacian (CSR in) | eigsh λ₂ (SA, k=2) | eigsh shift 2Δ (LA on 2Δ·I − L, k=2) | NetworkX algebraic_connectivity | eigsh spectral radius (LA, k=1) | dense eigvalsh of L |")
    print("|---|---|---|---|---|---|---|---|---|---|")
    for name, make in cases:
        h = make()
        n, m = h.number_of_nodes(), h.number_of_edges()
        t6, L = timed(lambda: nx.laplacian_matrix(h))
        L = L.astype(float).tocsr()
        A = nx.adjacency_matrix(h).astype(float).tocsr()
        t7, _ = timed(lambda: sp.sparse.csgraph.laplacian(A))
        dmax = max(d for _, d in h.degree())
        v0 = np.ones(n) + np.arange(n) / n
        t1, r1 = timed(lambda: sp.sparse.linalg.eigsh(L, k=2, which="SA", tol=1e-8, v0=v0)[0])
        S = (2 * dmax) * sp.sparse.identity(n, format="csr") - L
        t2, r2 = timed(lambda: 2 * dmax - sp.sparse.linalg.eigsh(S, k=2, which="LA", tol=1e-8, v0=v0)[0])
        t3, r3 = timed(lambda: nx.algebraic_connectivity(h, tol=1e-8, seed=1))
        t4, r4 = timed(lambda: sp.sparse.linalg.eigsh(A, k=1, which="LA", tol=1e-8, v0=v0)[0][0])
        t5 = None
        if n <= 10_000:
            t5, _ = timed(lambda: np.linalg.eigvalsh(L.toarray()))

        def f(t, r=None):
            if t is None:
                return "> 120 s"
            return f"{t:.1f} ms" + (f" ({np.min(r) if np.ndim(r) else r:.6g})" if r is not None else "")
        lam = r1[np.argsort(r1)[1]] if r1 is not None else None
        print(f"| {name} | {n} | {m} | {f(t6)} | {f(t7)} | {f(t1, lam)} | {f(t2, sorted(r2)[1] if r2 is not None else None)} | {f(t3, r3)} | {f(t4, r4)} | {f(t5)} |", flush=True)


# ============================================================================ main

def main():
    if "--bench" in sys.argv:
        bench()
        return
    define()
    number_rows()
    compute()
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
        global METHODS
        METHODS = ("tracemin_lu",)
        c = stress()
        print("stress: " + ", ".join(f"{v} {k}" for k, v in sorted(c.items())) +
              " checked against brute force, NetworkX and SciPy")
        for (lib, why), k in sorted(DISAGREE.items()):
            print(f"  known disagreement, {k} cases: {lib}: {why}")


if __name__ == "__main__":
    main()
