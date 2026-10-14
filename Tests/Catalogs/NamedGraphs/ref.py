#!/usr/bin/env python3
"""Reference model for the NamedGraphs factories (Tests/Catalogs/NamedGraphs).

Run: uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/NamedGraphs/ref.py [--write] [--stress]

The model builds each family exactly as api.md pins it: vertices 0..<n, undirected edges as
(u, v) with u < v sorted lexicographically, directed edges sorted row-major. Every row is checked
against
  * NetworkX 3.7: the same edge set after relabeling NetworkX's nodes by the documented numbering
    (complete_graph, complete_bipartite_graph, path_graph, cycle_graph, star_graph, wheel_graph,
    grid_2d_graph, grid_graph, hypercube_graph, petersen_graph, empty_graph), and the DiGraph
    variants NetworkX supports (complete, path, cycle, star, grid_2d);
  * igraph 1.0: the same edge set where igraph's numbering is ours (Full, Full_Bipartite, Ring,
    Star, Lattice with reversed dimensions, Hypercube) and isomorphism where it is not
    (Famous("Petersen"));
  * the family's laws: vertex and edge counts, degree sequence, and (for the directed form) the
    orientation rule of api.md.
--write regenerates cases.md; without it the run fails if cases.md differs. --stress checks every
family over a range of sizes against NetworkX and igraph.
"""
import itertools
import os
import sys

import igraph as ig
import networkx as nx

HERE = os.path.dirname(os.path.abspath(__file__))
INT_MAX = (1 << 63) - 1


class Trap(Exception):
    pass


def require(cond, msg):
    if not cond:
        raise Trap(msg)


# ---------------------------------------------------------------- the model

class G:
    """A generated graph: n vertices 0..<n, sorted edges, directed or not."""

    def __init__(self, n, edges, directed):
        self.n = n
        self.edges = edges
        self.directed = directed
        if directed:
            assert edges == sorted(set(edges)), "directed edges must be sorted row-major, no repeats"
        else:
            assert all(u < v for u, v in edges), "undirected edges are (u, v) with u < v"
            assert edges == sorted(set(edges)), "undirected edges must be sorted, no repeats"
        assert all(0 <= u < n and 0 <= v < n for u, v in edges)


def _undirected(n, pairs):
    return G(n, sorted({(min(u, v), max(u, v)) for u, v in pairs}), False)


def _both_arcs(g):
    """The symmetric digraph of an undirected graph (complete, grid, hypercube, Petersen)."""
    return G(g.n, sorted({(u, v) for u, v in g.edges} | {(v, u) for u, v in g.edges}), True)


def _count(n, name="vertexCount"):
    require(isinstance(n, int) and n >= 0, f"{name} {n} is negative")


def complete(n, directed=False):
    _count(n)
    # The kind's own count: n(n - 1) arcs, n(n - 1)/2 edges.
    require((n * (n - 1) if directed else n * (n - 1) // 2) <= INT_MAX, "edge count overflows Int")
    g = _undirected(n, itertools.combinations(range(n), 2))
    return _both_arcs(g) if directed else g


def complete_bipartite(a, b, directed=False):
    _count(a, "leftCount")
    _count(b, "rightCount")
    require(a + b <= INT_MAX and a * b <= INT_MAX, "count overflows Int")
    pairs = [(u, a + v) for u in range(a) for v in range(b)]
    if directed:
        require(2 * a * b <= INT_MAX, "count overflows Int")
        return _both_arcs(G(a + b, sorted(pairs), False))
    return G(a + b, sorted(pairs), False)


def path(n, directed=False):
    _count(n)
    pairs = [(i, i + 1) for i in range(n - 1)]
    return G(n, pairs, directed)  # directed: i -> i + 1


def cycle(n, directed=False):
    require(n >= 3, f"a cycle needs at least 3 vertices, not {n}")
    if directed:
        return G(n, sorted([(i, (i + 1) % n) for i in range(n)]), True)
    return _undirected(n, [(i, (i + 1) % n) for i in range(n)])


def star(n, directed=False):
    require(n >= 1, f"a star needs its hub: vertexCount {n} < 1")
    return G(n, [(0, i) for i in range(1, n)], directed)  # directed: hub -> leaf


def wheel(n, directed=False):
    require(n >= 4, f"a wheel needs a hub and a rim of at least 3: vertexCount {n} < 4")
    spokes = [(0, i) for i in range(1, n)]
    rim = [(i, i + 1) for i in range(1, n - 1)] + [(n - 1, 1)]
    if directed:  # hub -> rim, rim i -> i + 1 and n - 1 -> 1
        return G(n, sorted(spokes + rim), True)
    return _undirected(n, spokes + rim)


def grid(dims, periodic=False, directed=False):
    require(len(dims) >= 1, "grid needs at least one dimension")
    for d in dims:
        require(d >= 0, f"dimension {d} is negative")
    n = 1
    for d in dims:
        n *= d
        require(n <= INT_MAX, "vertex count overflows Int")
    strides = []
    s = 1
    for d in reversed(dims):
        strides.append(s)
        s *= d
    strides.reverse()  # dims[0] slowest, the last dimension fastest (row-major)
    pairs = []
    for v in range(n):
        for i, d in enumerate(dims):
            x = (v // strides[i]) % d
            if x + 1 < d:
                pairs.append((v, v + strides[i]))
            if periodic and d >= 3 and x == 0:
                pairs.append((v, v + (d - 1) * strides[i]))
    g = _undirected(n, pairs)
    return _both_arcs(g) if directed else g


def hypercube(d, directed=False):
    require(d >= 0, f"dimension {d} is negative")
    require(d <= 62, f"2^{d} vertices overflow Int")
    n = 1 << d
    require(d * n // (1 if directed else 2) <= INT_MAX, "edge count overflows Int")
    g = _undirected(n, [(v, v ^ (1 << k)) for v in range(n) for k in range(d) if not v >> k & 1])
    return _both_arcs(g) if directed else g


PETERSEN_ADJ = {0: [1, 4, 5], 1: [0, 2, 6], 2: [1, 3, 7], 3: [2, 4, 8], 4: [3, 0, 9],
                5: [0, 7, 8], 6: [1, 8, 9], 7: [2, 5, 9], 8: [3, 5, 6], 9: [4, 6, 7]}


def petersen(directed=False):
    g = _undirected(10, [(u, v) for u, vs in PETERSEN_ADJ.items() for v in vs])
    return _both_arcs(g) if directed else g


def empty(n, directed=False):
    _count(n)
    return G(n, [], directed)


def ladder(n, directed=False, circular=False):
    if circular:
        require(n >= 3, f"a circular ladder needs at least 3 rungs, not {n}")
    else:
        _count(n, "rungCount")
    rails = [(i, i + 1) for r in (0, n) for i in range(r, r + n - 1)]
    if circular:
        rails += [(0, n - 1), (n, 2 * n - 1)]
    g = _undirected(2 * n, rails + [(i, i + n) for i in range(n)])
    return _both_arcs(g) if directed else g


def circular_ladder(n, directed=False):
    return ladder(n, directed, circular=True)


def _clique_path(k, p, two, directed):
    require(k >= 2, f"{'a barbell' if two else 'a lollipop'} needs a clique of at least 2 vertices, not {k}")
    _count(p, "pathVertexCount")
    n = (2 if two else 1) * k + p
    require(n <= INT_MAX, "vertex count overflows Int")
    pairs = list(itertools.combinations(range(k), 2))
    pairs += [(i, i + 1) for i in range(k - 1, k + p - (0 if two else 1))]
    if two:
        pairs += list(itertools.combinations(range(k + p, n), 2))
    require(len(pairs) * (2 if directed else 1) <= INT_MAX, "edge count overflows Int")
    g = _undirected(n, pairs)
    return _both_arcs(g) if directed else g


def barbell(k, p, directed=False):
    return _clique_path(k, p, True, directed)


def lollipop(k, p, directed=False):
    return _clique_path(k, p, False, directed)


def complete_multipartite(sizes, directed=False):
    n = m = 0
    parts = []
    for s in sizes:
        _count(s, "part size")
        m += s * n
        require(m <= INT_MAX, "edge count overflows Int")
        parts.append(range(n, n + s))
        n += s
    pairs = [(u, v) for i, a in enumerate(parts) for b in parts[i + 1:] for u in a for v in b]
    if directed:
        require(2 * m <= INT_MAX, "edge count overflows Int")
        return _both_arcs(G(n, sorted(pairs), False))
    return G(n, sorted(pairs), False)


def turan_sizes(n, r):
    require(1 <= r <= n, f"a Turán graph needs 1 ≤ partCount ≤ vertexCount, not {r} and {n}")
    return [n // r] * (r - n % r) + [n // r + 1] * (n % r)


def turan(n, r, directed=False):
    return complete_multipartite(turan_sizes(n, r), directed)


def balanced_tree_count(r, h):
    _count(r, "branchingFactor")
    _count(h, "height")
    n, level = 1, 1
    for _ in range(h):
        if level == 0:
            break
        level *= r
        n += level
        require(n <= INT_MAX, "vertex count overflows Int")
    return n


def balanced_tree(r, h, directed=False):
    n = balanced_tree_count(r, h)
    return G(n, [((c - 1) // r, c) for c in range(1, n)], directed)  # directed: parent -> child


def tree_balanced(r, h):
    return balanced_tree(r, h)


def tree_path(n):
    require(n >= 1, "a Tree has at least one vertex")
    return path(n)


def tree_star(n):
    require(n >= 1, "a Tree has at least one vertex")
    return star(n)


def bipartite_complete(a, b):
    g = complete_bipartite(a, b)
    g.left = list(range(a))
    g.right = list(range(a, a + b))
    return g



# ---------------------------------------------------------------- the families added with the lattices

def circulant(n, offsets, directed=False):
    require(n >= 1, f"a circulant graph needs at least 1 vertex, not {n}")
    for o in offsets:
        require(o % n != 0, f"offset {o} is a multiple of vertexCount {n}: a self-loop")
    g = _undirected(n, [(i, (i + o) % n) for i in range(n) for o in offsets])
    return _both_arcs(g) if directed else g


def generalized_petersen(n, k, directed=False):
    require(n >= 3, f"a generalized Petersen graph needs an outer cycle of at least 3, not {n}")
    require(k >= 1 and 2 * k < n, f"step {k} is not in 1 ..< {n}/2")
    pairs = [(i, (i + 1) % n) for i in range(n)] + [(i, n + i) for i in range(n)]
    pairs += [(n + i, n + (i + k) % n) for i in range(n)]
    g = _undirected(2 * n, pairs)
    return _both_arcs(g) if directed else g


def kneser(n, k, directed=False):
    require(1 <= k <= n, f"subsetSize {k} is not in 1...{n}")
    import math
    require(math.comb(n, k) < INT_MAX, "vertex count overflows Int")
    subsets = list(itertools.combinations(range(n), k))  # lexicographic: vertex r is subsets[r]
    pairs = [(a, b) for a in range(len(subsets)) for b in range(a + 1, len(subsets))
             if not set(subsets[a]) & set(subsets[b])]
    g = G(len(subsets), pairs, False)
    return _both_arcs(g) if directed else g


def windmill(c, k, directed=False):
    require(c >= 2, f"a windmill needs at least 2 cliques, not {c}")
    require(k >= 2, f"a windmill's cliques need at least 2 vertices, not {k}")
    n = 1 + c * (k - 1)
    pairs = [(0, v) for v in range(1, n)]
    for j in range(c):
        pairs += list(itertools.combinations(range(1 + j * (k - 1), 1 + (j + 1) * (k - 1)), 2))
    g = _undirected(n, pairs)
    return _both_arcs(g) if directed else g


def binomial_tree(k, directed=False):
    require(k >= 0, f"order {k} is negative")
    require(k <= 62, f"2^{k} vertices overflow Int")
    n = 1 << k
    return G(n, sorted((c & (c - 1), c) for c in range(1, n)), directed)  # directed: parent -> child


def full_rary_tree(r, n, directed=False):
    require(r >= 1, f"branchingFactor {r} < 1")
    _count(n)
    return G(n, [((c - 1) // r, c) for c in range(1, n)], directed)  # directed: parent -> child


def tree_binomial(k):
    return binomial_tree(k)


def tree_full_rary(r, n):
    require(r >= 1, f"branchingFactor {r} < 1")
    require(n >= 1, "a Tree has at least one vertex")
    return full_rary_tree(r, n)


def de_bruijn(m, n, directed=True):
    require(m >= 1, f"alphabetSize {m} < 1")
    require(n >= 1, f"wordLength {n} < 1")
    words = list(itertools.product(range(m), repeat=n))  # lexicographic: vertex u is words[u]
    index = {w: i for i, w in enumerate(words)}
    return G(len(words), sorted((index[w], index[w[1:] + (a,)]) for w in words for a in range(m)), True)


def kautz(s, L, directed=True):
    require(s >= 2, f"alphabetSize {s} < 2")
    require(L >= 1, f"wordLength {L} < 1")
    words = [w for w in itertools.product(range(s), repeat=L) if all(x != y for x, y in zip(w, w[1:]))]
    index = {w: i for i, w in enumerate(words)}
    return G(len(words), sorted((index[w], index[w[1:] + (a,)]) for w in words for a in range(s) if a != w[-1]), True)


def _numbered(nodes, edges):
    """A graph on the given node keys, numbered in the order given."""
    index = {v: i for i, v in enumerate(nodes)}
    return _undirected(len(nodes), [(index[u], index[v]) for u, v in edges])


def triangular_lattice(m, n, directed=False):
    _count(m, "rowCount")
    _count(n, "columnCount")
    if m == 0 or n == 0:
        g = G(0, [], False)
        return _both_arcs(g) if directed else g
    N = (n + 1) // 2
    removed = {(N, j) for j in range(1, m + 1, 2)} if n % 2 else set()
    nodes = [(i, j) for j in range(m + 1) for i in range(N + 1) if (i, j) not in removed]  # row by row
    edges = [((i, j), (i + 1, j)) for j in range(m + 1) for i in range(N)]
    edges += [((i, j), (i, j + 1)) for j in range(m) for i in range(N + 1)]
    edges += [((i, j), (i + 1, j + 1)) for j in range(1, m, 2) for i in range(N)]
    edges += [((i + 1, j), (i, j + 1)) for j in range(0, m, 2) for i in range(N)]
    g = _numbered(nodes, [(u, v) for u, v in edges if u not in removed and v not in removed])
    return _both_arcs(g) if directed else g


def hexagonal_lattice(m, n, directed=False):
    _count(m, "rowCount")
    _count(n, "columnCount")
    if m == 0 or n == 0:
        g = G(0, [], False)
        return _both_arcs(g) if directed else g
    M = 2 * m
    removed = {(0, M + 1), (n, (M + 1) * (n % 2))}
    nodes = [(i, j) for i in range(n + 1) for j in range(M + 2) if (i, j) not in removed]  # column by column
    edges = [((i, j), (i, j + 1)) for i in range(n + 1) for j in range(M + 1)]
    edges += [((i, j), (i + 1, j)) for i in range(n) for j in range(M + 2) if i % 2 == j % 2]
    g = _numbered(nodes, [(u, v) for u, v in edges if u not in removed and v not in removed])
    return _both_arcs(g) if directed else g


def lcf(n, shifts, r, directed=False):
    require(n >= 3, f"an LCF graph needs a cycle of at least 3 vertices, not {n}")
    _count(r, "repeatCount")
    pairs = [(i, (i + 1) % n) for i in range(n)]
    for i in range(len(shifts) * r):
        s = shifts[i % len(shifts)]
        u, v = i % n, (i + s) % n
        require(u != v, f"shift {s} is a multiple of vertexCount {n}: a self-loop")
        pairs.append((u, v))
    g = _undirected(n, pairs)
    return _both_arcs(g) if directed else g


LCF_NAMED = {
    "heawood": (14, [5, -5], 7), "moebiusKantor": (16, [5, -5], 8), "pappus": (18, [5, 7, -7, 7, -7, -5], 3),
    "desargues": (20, [5, -5, 9, -9], 5), "dodecahedral": (20, [10, 7, 4, -4, -7, 10, -4, 7, -7, 4], 2),
    "frucht": (12, [-5, -2, -4, 2, 5, -2, 2, 5, -2, -5, 4, 2], 1),
}


def lcf_named(name, directed=False):
    return lcf(*LCF_NAMED[name], directed)


def icosahedral(directed=False):
    pairs = []
    for t in range(5):
        u = (t + 1) % 5
        pairs += [(0, 1 + t), (1 + t, 1 + u), (1 + t, 6 + t), (1 + t, 6 + u), (6 + t, 6 + u), (6 + t, 11)]
    g = _undirected(12, pairs)
    return _both_arcs(g) if directed else g


TUTTE_FRAGMENT = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 4), (2, 5), (3, 6), (3, 7), (4, 8), (5, 9), (5, 10),
                  (6, 11), (7, 8), (7, 12), (8, 10), (9, 13), (9, 14), (10, 14), (11, 12), (11, 13), (12, 14)]


def tutte(directed=False):
    pairs = []
    for f in range(3):
        base, nxt = 1 + 15 * f, 1 + 15 * ((f + 1) % 3)
        pairs += [(0, base), (base + 13, nxt + 6)] + [(base + u, base + v) for u, v in TUTTE_FRAGMENT]
    g = _undirected(46, pairs)
    return _both_arcs(g) if directed else g


CHVATAL = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7),
           (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]


def chvatal(directed=False):
    g = _undirected(12, CHVATAL)
    return _both_arcs(g) if directed else g


def hoffman_singleton(directed=False):
    pairs = []
    for h in range(5):
        for j in range(5):
            pairs += [(5 * h + j, 5 * h + (j + 1) % 5), (25 + 5 * h + j, 25 + 5 * h + (j + 2) % 5)]
            pairs += [(5 * h + j, 25 + 5 * i + (h * i + j) % 5) for i in range(5)]
    g = _undirected(50, pairs)
    return _both_arcs(g) if directed else g


NEW_FAMILIES = {"circulant", "generalizedPetersen", "kneser", "windmill", "binomialTree", "fullRaryTree",
                "deBruijn", "kautz", "triangularLattice", "hexagonalLattice", "lcf", "heawood", "moebiusKantor",
                "pappus", "desargues", "dodecahedral", "frucht", "icosahedral", "tutte", "chvatal",
                "hoffmanSingleton"}


def new_oracle(family, args, directed, g):
    """Checks a family added with the lattices against NetworkX (exact where it numbers the same
    way, isomorphism otherwise) and igraph (de Bruijn and Kautz, exact)."""
    mine = set(g.edges)
    if family in ("deBruijn", "kautz"):
        H = ig.Graph.De_Bruijn(*args) if family == "deBruijn" else ig.Graph.Kautz(args[0] - 1, args[1] - 1)
        assert (H.vcount(), set(H.get_edgelist())) == (g.n, mine), f"igraph disagrees on {family}{args}"
        return
    if directed and family in ("binomialTree", "fullRaryTree"):
        H = (nx.binomial_tree if family == "binomialTree" else nx.full_rary_tree)(*args, create_using=nx.DiGraph)
        assert (H.number_of_nodes(), set(H.edges())) == (g.n, mine), f"NetworkX disagrees on {family}{args} directed"
        return
    if directed:
        und = {(min(u, v), max(u, v)) for u, v in mine}
        assert mine == und | {(v, u) for u, v in und}, f"{family} directed is not both arcs"
        g = G(g.n, sorted(und), False)
        mine = und
    exact = {
        "circulant": lambda: nx.circulant_graph(*args),
        "generalizedPetersen": lambda: nx.generalized_petersen_graph(*args),
        "kneser": lambda: nx.relabel_nodes(nx.kneser_graph(*args),
                                           {s: i for i, s in enumerate(itertools.combinations(range(args[0]), args[1]))}),
        "windmill": lambda: nx.windmill_graph(*args),
        "binomialTree": lambda: nx.binomial_tree(*args),
        "fullRaryTree": lambda: nx.full_rary_tree(*args),
        "triangularLattice": lambda: nx.convert_node_labels_to_integers(nx.triangular_lattice_graph(*args, with_positions=False)),
        "hexagonalLattice": lambda: nx.convert_node_labels_to_integers(nx.hexagonal_lattice_graph(*args, with_positions=False)),
        "lcf": lambda: nx.LCF_graph(*args),
        "heawood": nx.heawood_graph, "moebiusKantor": nx.moebius_kantor_graph, "pappus": nx.pappus_graph,
        "desargues": nx.desargues_graph, "dodecahedral": nx.dodecahedral_graph, "chvatal": nx.chvatal_graph,
    }
    iso = {"frucht": nx.frucht_graph, "icosahedral": nx.icosahedral_graph, "tutte": nx.tutte_graph,
           "hoffmanSingleton": nx.hoffman_singleton_graph}
    if family == "kneser" and 2 * args[1] > args[0]:
        H = nx.kneser_graph(*args)
        assert H.number_of_edges() == 0 and len(mine) == 0 and H.number_of_nodes() == g.n
        return
    if family in exact:
        H = exact[family]()
        assert (H.number_of_nodes(), {(min(u, v), max(u, v)) for u, v in H.edges()}) == (g.n, mine), \
            f"NetworkX disagrees on {family}{args}"
    else:
        H = iso[family]()
        assert nx.is_isomorphic(nx.Graph(list(mine)), H) and H.number_of_nodes() == g.n, f"NetworkX: {family} not isomorphic"

# ---------------------------------------------------------------- oracles

def nx_relabeled(H, key):
    """H's edges with nodes renamed by key, as a set of pairs (sorted pairs when undirected)."""
    if H.is_directed():
        return H.number_of_nodes(), {(key(u), key(v)) for u, v in H.edges()}
    return H.number_of_nodes(), {(min(key(u), key(v)), max(key(u), key(v))) for u, v in H.edges()}


def ident(x):
    return x


def nx_oracle(family, args, directed):
    """(n, edge set) from NetworkX under our numbering, or None when NetworkX has no such graph."""
    D = nx.DiGraph if directed else nx.Graph
    if family == "complete":
        return nx_relabeled(nx.complete_graph(args[0], create_using=D), ident)
    if family == "path":
        return nx_relabeled(nx.path_graph(args[0], create_using=D), ident)
    if family == "cycle":
        return nx_relabeled(nx.cycle_graph(args[0], create_using=D), ident)
    if family == "star":
        n = args[0]
        if n == 1:
            return nx_relabeled(nx.empty_graph(1, create_using=D), ident)
        return nx_relabeled(nx.star_graph(n - 1, create_using=D), ident)  # NetworkX: n - 1 leaves
    if family == "empty":
        return nx_relabeled(nx.empty_graph(args[0], create_using=D), ident)
    if family == "grid":
        dims, periodic = args
        if directed:
            if len(dims) != 2:
                return None
            H = nx.grid_2d_graph(dims[0], dims[1], periodic=periodic, create_using=nx.DiGraph)
            return nx_relabeled(H, lambda t: t[0] * dims[1] + t[1])
        if periodic and any(d < 3 for d in dims):
            # NetworkX's grid_graph wraps a dimension of 1 into a self-loop; grid_2d_graph does not.
            if len(dims) != 2:
                return None
            H = nx.grid_2d_graph(dims[0], dims[1], periodic=True)
            return nx_relabeled(H, lambda t: t[0] * dims[1] + t[1])
        H = nx.grid_graph(dim=list(dims), periodic=periodic)

        def key(t):
            t = t if isinstance(t, tuple) else (t,)
            v = 0
            for x, d in zip(reversed(t), dims):  # NetworkX's tuple lists the last dimension first
                v = v * d + x
            return v
        return nx_relabeled(H, key)
    if family == "balancedTree":
        return nx_relabeled(nx.balanced_tree(args[0], args[1], create_using=D), ident)
    if directed:
        if family in ("hypercube", "petersen", "ladder", "circularLadder", "barbell", "lollipop",
                      "completeBipartite", "completeMultipartite", "turan"):
            und = nx_oracle(family, args, False)
            return None if und is None else (und[0], und[1] | {(v, u) for u, v in und[1]})
        return None  # NetworkX has no directed wheel
    if family == "completeBipartite":
        return nx_relabeled(nx.complete_bipartite_graph(*args), ident)
    if family == "wheel":
        return nx_relabeled(nx.wheel_graph(args[0]), ident)
    if family == "hypercube":
        if args[0] == 0:
            return None  # NetworkX's hypercube_graph(0) is the null graph; Q0 is K1 (igraph agrees)
        return nx_relabeled(nx.hypercube_graph(args[0]),
                            lambda t: sum(b << i for i, b in enumerate(t)) if isinstance(t, tuple) else t)
    if family == "petersen":
        return nx_relabeled(nx.petersen_graph(), ident)
    if family == "ladder":
        return nx_relabeled(nx.ladder_graph(args[0]), ident)
    if family == "circularLadder":
        return nx_relabeled(nx.circular_ladder_graph(args[0]), ident)
    if family == "barbell":
        return nx_relabeled(nx.barbell_graph(*args), ident)
    if family == "lollipop":
        return nx_relabeled(nx.lollipop_graph(*args), ident)
    if family == "completeMultipartite":
        return nx_relabeled(nx.complete_multipartite_graph(*args[0]), ident)
    if family == "turan":
        return nx_relabeled(nx.turan_graph(*args), ident)
    raise AssertionError(family)


def ig_oracle(family, args, directed):
    """(n, edge set, exact) from igraph: exact numbering when the flag is set, else isomorphism only."""
    if family == "complete":
        H = ig.Graph.Full(args[0], directed=directed)
    elif family == "completeBipartite":
        H = ig.Graph.Full_Bipartite(args[0], args[1], directed=directed)  # mode="all", the default
    elif family == "path":
        H = ig.Graph.Ring(args[0], directed=directed, circular=False)
    elif family == "cycle":
        H = ig.Graph.Ring(args[0], directed=directed, circular=True)
    elif family == "star":
        if args[0] == 1:
            return None  # igraph 1.0's Star(1) has no vertices
        H = ig.Graph.Star(args[0], mode="out" if directed else "undirected", center=0)
    elif family == "grid":
        dims, periodic = args
        if periodic and any(d < 3 for d in dims):
            return None  # igraph wraps short dimensions into loops and multi-edges
        H = ig.Graph.Lattice(list(reversed(dims)), circular=periodic, directed=directed, mutual=True)
    elif family == "hypercube" and not directed:
        H = ig.Graph.Hypercube(args[0])
    elif family == "petersen" and not directed:
        H = ig.Graph.Famous("Petersen")
        return H.vcount(), H, False
    elif family == "empty":
        H = ig.Graph(n=args[0], directed=directed)
    elif family == "ladder" and not directed and args[0] >= 1:
        H = ig.Graph.Lattice([args[0], 2], circular=False)  # rails as the grid 2 × n, row-major
    elif family == "balancedTree":
        H = ig.Graph.Tree(balanced_tree_count(*args), args[0] if args[0] > 0 else 1,
                          mode="out" if directed else "undirected")
    else:
        return None
    E = H.get_edgelist()
    if directed:
        return H.vcount(), set(E), True
    return H.vcount(), {(min(u, v), max(u, v)) for u, v in E}, True


def check(family, args, directed, g):
    if family in NEW_FAMILIES:
        new_oracle(family, args, directed, g)
        return
    o = nx_oracle(family, args, directed)
    if o is not None:
        assert o == (g.n, set(g.edges)), f"NetworkX disagrees on {family}{args} directed={directed}"
    o = ig_oracle(family, args, directed)
    if o is not None:
        n, H, exact = o
        if exact:
            assert (n, H) == (g.n, set(g.edges)), f"igraph disagrees on {family}{args} directed={directed}"
        else:
            mine = ig.Graph(n=g.n, edges=g.edges)
            assert mine.isomorphic(H), f"igraph: {family} not isomorphic"
    # laws
    m_expected = {
        "complete": lambda n: n * (n - 1) // (1 if directed else 2),
        "path": lambda n: max(n - 1, 0),
        "cycle": lambda n: n,
        "star": lambda n: n - 1,
        "wheel": lambda n: 2 * (n - 1),
        "empty": lambda n: 0,
    }
    if family in m_expected:
        assert g.n == args[0] and len(g.edges) == m_expected[family](args[0])
    if family == "completeBipartite":
        assert g.n == args[0] + args[1] and len(g.edges) == args[0] * args[1] * (2 if directed else 1)
    if family in ("ladder", "circularLadder"):
        k = args[0]
        assert g.n == 2 * k and len(g.edges) == (3 * k if family == "circularLadder" else max(3 * k - 2, 0)) * (2 if directed else 1)
    if family in ("barbell", "lollipop"):
        k, p = args
        two = family == "barbell"
        assert g.n == (2 if two else 1) * k + p
        assert len(g.edges) == ((2 if two else 1) * (k * (k - 1) // 2) + p + (1 if two else 0)) * (2 if directed else 1)
    if family in ("completeMultipartite", "turan"):
        sizes = args[0] if family == "completeMultipartite" else turan_sizes(*args)
        assert g.n == sum(sizes) and len(g.edges) == (sum(sizes) ** 2 - sum(x * x for x in sizes)) // (1 if directed else 2)
        assert directed or all(u < v for u, v in g.edges)
    if family == "balancedTree":
        r, h = args
        assert g.n == (h + 1 if r == 1 else (r ** (h + 1) - 1) // (r - 1) if r > 1 else 1) and len(g.edges) == g.n - 1
    if family == "hypercube":
        d = args[0]
        assert g.n == 1 << d and len(g.edges) == (d << d >> 1) * (2 if directed else 1)
    if family == "petersen":
        assert g.n == 10 and len(g.edges) == (30 if directed else 15)
        assert nx.is_isomorphic(nx.Graph(list(set((min(u, v), max(u, v)) for u, v in g.edges))), nx.petersen_graph())


# ---------------------------------------------------------------- rendering

def fmt_edges(g):
    sep = "→" if g.directed else "–"
    return "[" + ", ".join(f"{u}{sep}{v}" for u, v in g.edges) + "]"


def degrees(g):
    if g.directed:
        out = [0] * g.n
        inn = [0] * g.n
        for u, v in g.edges:
            out[u] += 1
            inn[v] += 1
        return out, inn
    d = [0] * g.n
    for u, v in g.edges:
        d[u] += 1
        d[v] += 1
    return d


def summary(g, full=True):
    s = f"n {g.n}; m {len(g.edges)}"
    if g.directed:
        out, inn = degrees(g)
        s += f"; out {out}; in {inn}" if g.n <= 16 else ""
    else:
        d = degrees(g)
        s += f"; deg {d}" if g.n <= 16 else f"; deg {min(d) if d else '-'}…{max(d) if d else '-'}"
    if full:
        s += f"; E {fmt_edges(g)}"
    return s


ROWS = []


def row(group, case, call, fn, *, family=None, args=None, directed=False, full=True, extra=None):
    try:
        g = fn()
    except Trap as t:
        ROWS.append((group, case, call, f"**trap**: {t}"))
        return
    if family is not None:
        check(family, args, directed, g)
    text = summary(g, full)
    if extra:
        text += "; " + extra(g)
    ROWS.append((group, case, call, text))


def build_rows():
    U = "UndirectedAdjacencyList<Int>"
    C = "CompressedSparseRow"
    # complete
    for n in (0, 1, 2, 3, 5):
        row("Complete", f"K{n}", f"{U}.complete(vertexCount: {n})", lambda n=n: complete(n),
            family="complete", args=(n,))
    for n in (0, 1, 3):
        row("Complete", f"K{n} directed: both arcs, row-major", f"{C}.complete(vertexCount: {n})",
            lambda n=n: complete(n, True), family="complete", args=(n,), directed=True)
    row("Complete", "K60 counts only", f"{U}.complete(vertexCount: 60)", lambda: complete(60),
        family="complete", args=(60,), full=False)
    row("Complete", "negative count", f"{U}.complete(vertexCount: -1)", lambda: complete(-1))
    row("Complete", "n(n − 1) overflows Int", f"{C}.complete(vertexCount: 1 << 32)", lambda: complete(1 << 32, True))
    # complete bipartite
    for a, b in ((0, 0), (0, 3), (1, 1), (2, 3), (3, 2)):
        row("CompleteBipartite", f"K{a},{b}: left 0..<{a}, right {a}..<{a + b}",
            f"{U}.completeBipartite(leftCount: {a}, rightCount: {b})",
            lambda a=a, b=b: complete_bipartite(a, b), family="completeBipartite", args=(a, b))
    row("CompleteBipartite", "K2,3 directed: both arcs", f"{C}.completeBipartite(leftCount: 2, rightCount: 3)",
        lambda: complete_bipartite(2, 3, True), family="completeBipartite", args=(2, 3), directed=True)
    row("CompleteBipartite", "BipartiteGraph sides", "BipartiteGraph<Int>.completeBipartite(leftCount: 2, rightCount: 2)",
        lambda: bipartite_complete(2, 2), family="completeBipartite", args=(2, 2),
        extra=lambda g: f"left {g.left}; right {g.right}")
    row("CompleteBipartite", "BipartiteGraph with an empty side", "BipartiteGraph<Int>.completeBipartite(leftCount: 0, rightCount: 2)",
        lambda: bipartite_complete(0, 2), family="completeBipartite", args=(0, 2),
        extra=lambda g: f"left {g.left}; right {g.right}")
    row("CompleteBipartite", "negative side", f"{U}.completeBipartite(leftCount: 2, rightCount: -1)",
        lambda: complete_bipartite(2, -1))
    # path
    for n in (0, 1, 2, 5):
        row("Path", f"P{n}", f"{U}.path(vertexCount: {n})", lambda n=n: path(n), family="path", args=(n,))
    row("Path", "P4 directed: i → i + 1", f"{C}.path(vertexCount: 4)", lambda: path(4, True),
        family="path", args=(4,), directed=True)
    row("Path", "Tree.path", "Tree<Int>.path(vertexCount: 4)", lambda: tree_path(4), family="path", args=(4,))
    row("Path", "Tree.path(1) is one vertex", "Tree<Int>.path(vertexCount: 1)", lambda: tree_path(1),
        family="path", args=(1,))
    row("Path", "Tree.path(0): a tree is never empty", "Tree<Int>.path(vertexCount: 0)", lambda: tree_path(0))
    row("Path", "negative count", f"{U}.path(vertexCount: -2)", lambda: path(-2))
    # cycle
    for n in (3, 4, 6):
        row("Cycle", f"C{n}: closing edge stored as 0–{n - 1}", f"{U}.cycle(vertexCount: {n})",
            lambda n=n: cycle(n), family="cycle", args=(n,))
    row("Cycle", "C4 directed: i → i + 1 mod n, row-major", f"{C}.cycle(vertexCount: 4)",
        lambda: cycle(4, True), family="cycle", args=(4,), directed=True)
    for n in (0, 1, 2):
        row("Cycle", f"C{n} is not a simple cycle", f"{U}.cycle(vertexCount: {n})", lambda n=n: cycle(n))
    row("Cycle", "C2 directed is trapped too (one rule for every type)", f"{C}.cycle(vertexCount: 2)",
        lambda: cycle(2, True))
    # star
    for n in (1, 2, 5):
        row("Star", f"star of {n} vertices: hub 0", f"{U}.star(vertexCount: {n})", lambda n=n: star(n),
            family="star", args=(n,))
    row("Star", "directed: hub → leaf", f"{C}.star(vertexCount: 4)", lambda: star(4, True),
        family="star", args=(4,), directed=True)
    row("Star", "Tree.star", "Tree<Int>.star(vertexCount: 4)", lambda: tree_star(4), family="star", args=(4,))
    row("Star", "no hub", f"{U}.star(vertexCount: 0)", lambda: star(0))
    row("Star", "NetworkX's star_graph(4) has 5 vertices; ours counts vertices", f"{U}.star(vertexCount: 5)",
        lambda: star(5), family="star", args=(5,), full=False)
    # wheel
    for n in (4, 5, 7):
        row("Wheel", f"W{n}: hub 0, rim 1..<{n}", f"{U}.wheel(vertexCount: {n})", lambda n=n: wheel(n),
            family="wheel", args=(n,))
    row("Wheel", "W4 is K4", f"{U}.wheel(vertexCount: 4) == {U}.complete(vertexCount: 4)",
        lambda: wheel(4), extra=lambda g: f"equal {str(g.edges == complete(4).edges).lower()}", full=False)
    row("Wheel", "directed: hub → rim, rim cycle 1 → 2 → … → n − 1 → 1", f"{C}.wheel(vertexCount: 5)",
        lambda: wheel(5, True))
    for n in (0, 3):
        row("Wheel", f"W{n}: rim shorter than 3", f"{U}.wheel(vertexCount: {n})", lambda n=n: wheel(n))
    # grid
    for dims, per in (([3], False), ([2, 3], False), ([3, 3], False), ([2, 2, 2], False), ([0, 4], False),
                      ([1, 1], False), ([3], True), ([3, 4], True), ([2, 3], True), ([1, 3], True),
                      ([3, 3, 3], True)):
        row("Grid", f"{'×'.join(map(str, dims))}{' periodic' if per else ''}",
            f"{U}.grid(dimensions: {dims}{', periodic: true' if per else ''})",
            lambda dims=dims, per=per: grid(dims, per), family="grid", args=(dims, per),
            full=(len(dims) < 3 or not per))
    row("Grid", "2×3 directed: both arcs", f"{C}.grid(dimensions: [2, 3])", lambda: grid([2, 3], directed=True),
        family="grid", args=([2, 3], False), directed=True)
    row("Grid", "3×3 periodic directed", f"{C}.grid(dimensions: [3, 3], periodic: true)",
        lambda: grid([3, 3], True, True), family="grid", args=([3, 3], True), directed=True, full=False)
    row("Grid", "100×100 counts", f"{U}.grid(dimensions: [100, 100])", lambda: grid([100, 100]),
        family="grid", args=([100, 100], False), full=False)
    row("Grid", "no dimensions", f"{U}.grid(dimensions: [])", lambda: grid([]))
    row("Grid", "negative dimension", f"{U}.grid(dimensions: [3, -1])", lambda: grid([3, -1]))
    row("Grid", "vertex count overflows Int", f"{U}.grid(dimensions: [1 << 32, 1 << 32])",
        lambda: grid([1 << 32, 1 << 32]))
    # hypercube
    for d in (0, 1, 2, 3):
        row("Hypercube", f"Q{d}: u – u ^ (1 << k)", f"{U}.hypercube(dimension: {d})", lambda d=d: hypercube(d),
            family="hypercube", args=(d,))
    row("Hypercube", "Q2 directed: both arcs", f"{C}.hypercube(dimension: 2)", lambda: hypercube(2, True),
        family="hypercube", args=(2,), directed=True)
    row("Hypercube", "Q10 counts", f"{U}.hypercube(dimension: 10)", lambda: hypercube(10),
        family="hypercube", args=(10,), full=False)
    row("Hypercube", "negative dimension", f"{U}.hypercube(dimension: -1)", lambda: hypercube(-1))
    row("Hypercube", "2^63 vertices overflow Int", f"{U}.hypercube(dimension: 63)", lambda: hypercube(63))
    # petersen
    row("Petersen", "NetworkX's numbering: outer 0–4, spokes i–i+5, inner pentagram",
        f"{U}.petersen()", lambda: petersen(), family="petersen", args=())
    row("Petersen", "directed: both arcs", f"{C}.petersen()", lambda: petersen(True), family="petersen",
        args=(), directed=True, full=False)
    # empty
    for n in (0, 1, 4):
        row("Empty", f"empty graph on {n}", f"{U}.empty(vertexCount: {n})", lambda n=n: empty(n),
            family="empty", args=(n,))
    row("Empty", "directed", f"{C}.empty(vertexCount: 3)", lambda: empty(3, True), family="empty",
        args=(3,), directed=True)
    row("Empty", "negative count", f"{U}.empty(vertexCount: -1)", lambda: empty(-1))
    # representation parity: one family on every conformer gives the same edge list
    representation_rows(U, C)
    # the families added after the first catalog
    more_rows(U, C)
    lattice_rows(U, C)


def representation_rows(U, C):
    for rep in ("AdjacencyList<Int>", "AdjacencyMatrix", "StableDirectedGraph<Int>", "DirectedPseudograph<Int>",
                "DirectedMultigraph<Int>"):
        row("Representations", f"{rep}: same arcs, edges in row-major order", f"{rep}.cycle(vertexCount: 4)",
            lambda: cycle(4, True), family="cycle", args=(4,), directed=True)
    for rep in ("Pseudograph<Int>", "Multigraph<Int>"):
        row("Representations", f"{rep}: same edges, sorted", f"{rep}.wheel(vertexCount: 4)", lambda: wheel(4),
            family="wheel", args=(4,))


def more_rows(U, C):
    # ladder
    for n, what in ((0, "L0 is the null graph"), (1, "L1 is K2"), (4, "L4: rails 0..<4 and 4..<8, rungs i–i+4")):
        row("Ladder", what, f"{U}.ladder(rungCount: {n})",
            lambda n=n: ladder(n), family="ladder", args=(n,))
    row("Ladder", "L3 directed: both arcs", f"{C}.ladder(rungCount: 3)", lambda: ladder(3, True),
        family="ladder", args=(3,), directed=True)
    row("Ladder", "negative count", f"{U}.ladder(rungCount: -1)", lambda: ladder(-1))
    # circular ladder
    for n in (3, 4):
        row("CircularLadder", f"CL{n}: each rail closed by its first and last vertex",
            f"{U}.circularLadder(rungCount: {n})", lambda n=n: circular_ladder(n), family="circularLadder", args=(n,))
    row("CircularLadder", "CL3 directed: both arcs", f"{C}.circularLadder(rungCount: 3)",
        lambda: circular_ladder(3, True), family="circularLadder", args=(3,), directed=True)
    row("CircularLadder", "CL2: the rails are not cycles (NetworkX returns C4)", f"{U}.circularLadder(rungCount: 2)",
        lambda: circular_ladder(2))
    # barbell
    for k, p in ((2, 0), (3, 2), (4, 0)):
        row("Barbell", f"two K{k} joined by a path of {p}", f"{U}.barbell(cliqueVertexCount: {k}, pathVertexCount: {p})",
            lambda k=k, p=p: barbell(k, p), family="barbell", args=(k, p))
    row("Barbell", "directed: both arcs", f"{C}.barbell(cliqueVertexCount: 3, pathVertexCount: 1)",
        lambda: barbell(3, 1, True), family="barbell", args=(3, 1), directed=True)
    row("Barbell", "clique of 1", f"{U}.barbell(cliqueVertexCount: 1, pathVertexCount: 2)", lambda: barbell(1, 2))
    row("Barbell", "negative path", f"{U}.barbell(cliqueVertexCount: 3, pathVertexCount: -1)", lambda: barbell(3, -1))
    # lollipop
    for k, p in ((2, 0), (3, 2), (4, 1)):
        row("Lollipop", f"K{k} with a path of {p} at {k - 1}", f"{U}.lollipop(cliqueVertexCount: {k}, pathVertexCount: {p})",
            lambda k=k, p=p: lollipop(k, p), family="lollipop", args=(k, p))
    row("Lollipop", "directed: both arcs", f"{C}.lollipop(cliqueVertexCount: 3, pathVertexCount: 2)",
        lambda: lollipop(3, 2, True), family="lollipop", args=(3, 2), directed=True)
    row("Lollipop", "clique of 1", f"{U}.lollipop(cliqueVertexCount: 1, pathVertexCount: 2)", lambda: lollipop(1, 2))
    row("Lollipop", "negative path", f"{U}.lollipop(cliqueVertexCount: 3, pathVertexCount: -1)", lambda: lollipop(3, -1))
    # complete multipartite
    for sizes in ([], [2, 0, 1], [1, 2, 3], [1, 1, 1, 1]):
        row("CompleteMultipartite", f"parts {sizes}", f"{U}.completeMultipartite(partSizes: {sizes})",
            lambda sizes=sizes: complete_multipartite(sizes), family="completeMultipartite", args=(sizes,))
    row("CompleteMultipartite", "directed: both arcs", f"{C}.completeMultipartite(partSizes: [1, 2, 3])",
        lambda: complete_multipartite([1, 2, 3], True), family="completeMultipartite", args=([1, 2, 3],), directed=True)
    row("CompleteMultipartite", "negative part size", f"{U}.completeMultipartite(partSizes: [2, -1])",
        lambda: complete_multipartite([2, -1]))
    row("CompleteMultipartite", "edge count overflows Int", f"{U}.completeMultipartite(partSizes: [1 << 32, 1 << 32])",
        lambda: complete_multipartite([1 << 32, 1 << 32]))
    # Turán
    for n, r, what in ((5, 2, ": parts [2, 3], smaller first"), (7, 3, ": parts [2, 2, 3]"), (4, 4, " is K4"),
                       (4, 1, ": one part, no edges")):
        row("Turan", f"T({n}, {r}){what}", f"{U}.turan(vertexCount: {n}, partCount: {r})",
            lambda n=n, r=r: turan(n, r), family="turan", args=(n, r))
    row("Turan", "directed: both arcs", f"{C}.turan(vertexCount: 5, partCount: 2)",
        lambda: turan(5, 2, True), family="turan", args=(5, 2), directed=True)
    row("Turan", "no parts", f"{U}.turan(vertexCount: 5, partCount: 0)", lambda: turan(5, 0))
    row("Turan", "more parts than vertices", f"{U}.turan(vertexCount: 5, partCount: 6)", lambda: turan(5, 6))
    # balanced tree
    for r, h, what in ((2, 2, ": children of p are 2p + 1, 2p + 2"), (3, 2, ""), (1, 3, " is the path P4"),
                       (0, 3, " is the root alone"), (2, 0, " is the root alone")):
        row("BalancedTree", f"r = {r}, h = {h}{what}",
            f"{U}.balancedTree(branchingFactor: {r}, height: {h})", lambda r=r, h=h: balanced_tree(r, h),
            family="balancedTree", args=(r, h))
    row("BalancedTree", "directed: parent → child", f"{C}.balancedTree(branchingFactor: 2, height: 2)",
        lambda: balanced_tree(2, 2, True), family="balancedTree", args=(2, 2), directed=True)
    row("BalancedTree", "Tree.balancedTree", "Tree<Int>.balancedTree(branchingFactor: 2, height: 3)",
        lambda: tree_balanced(2, 3), family="balancedTree", args=(2, 3))
    row("BalancedTree", "negative height", f"{U}.balancedTree(branchingFactor: 2, height: -1)",
        lambda: balanced_tree(2, -1))
    row("BalancedTree", "negative branching factor", f"{U}.balancedTree(branchingFactor: -1, height: 2)",
        lambda: balanced_tree(-1, 2))
    row("BalancedTree", "vertex count overflows Int", f"{U}.balancedTree(branchingFactor: 2, height: 63)",
        lambda: balanced_tree(2, 63))


def lattice_rows(U, C):
    A, P = "AdjacencyList<Int>", "DirectedPseudograph<Int>"
    # circulant
    for n, offs, what in ((6, [1, 2], ""), (5, [1], " is C5"), (8, [1, 4], ": offset n/2 gives each edge once"),
                          (6, [2, -2, 4], ": 2, −2 and 4 are one offset"), (2, [1], " is K2"), (1, [], " is K1")):
        row("Circulant", f"C{n}({', '.join(map(str, offs))}){what}", f"{U}.circulant(vertexCount: {n}, offsets: {offs})",
            lambda n=n, offs=offs: circulant(n, offs), family="circulant", args=(n, offs))
    row("Circulant", "directed: both arcs", f"{C}.circulant(vertexCount: 6, offsets: [1, 2])",
        lambda: circulant(6, [1, 2], True), family="circulant", args=(6, [1, 2]), directed=True)
    row("Circulant", "an offset that is a multiple of n is a self-loop", f"{U}.circulant(vertexCount: 6, offsets: [1, 6])",
        lambda: circulant(6, [1, 6]))
    row("Circulant", "no vertices", f"{U}.circulant(vertexCount: 0, offsets: [])", lambda: circulant(0, []))
    # generalized Petersen
    for n, k, what in ((5, 2, " is the Petersen graph"), (4, 1, " is the cube"), (7, 2, ""), (3, 1, " is the prism")):
        row("GeneralizedPetersen", f"GP({n}, {k}){what}", f"{U}.generalizedPetersen(outerCycleLength: {n}, step: {k})",
            lambda n=n, k=k: generalized_petersen(n, k), family="generalizedPetersen", args=(n, k))
    row("GeneralizedPetersen", "directed: both arcs", f"{C}.generalizedPetersen(outerCycleLength: 5, step: 2)",
        lambda: generalized_petersen(5, 2, True), family="generalizedPetersen", args=(5, 2), directed=True)
    row("GeneralizedPetersen", "step 0", f"{U}.generalizedPetersen(outerCycleLength: 5, step: 0)",
        lambda: generalized_petersen(5, 0))
    row("GeneralizedPetersen", "step n/2 repeats the inner edges", f"{U}.generalizedPetersen(outerCycleLength: 6, step: 3)",
        lambda: generalized_petersen(6, 3))
    row("GeneralizedPetersen", "outer cycle of 2", f"{U}.generalizedPetersen(outerCycleLength: 2, step: 1)",
        lambda: generalized_petersen(2, 1))
    # Kneser
    for n, k, what in ((5, 2, ": the Petersen graph, subsets in lexicographic order"), (4, 1, " is K4"),
                       (5, 3, ": n < 2k, no edges"), (6, 2, ""), (1, 1, ": one vertex")):
        row("Kneser", f"KG({n}, {k}){what}", f"{U}.kneser(setSize: {n}, subsetSize: {k})",
            lambda n=n, k=k: kneser(n, k), family="kneser", args=(n, k))
    row("Kneser", "directed: both arcs", f"{C}.kneser(setSize: 5, subsetSize: 2)", lambda: kneser(5, 2, True),
        family="kneser", args=(5, 2), directed=True)
    row("Kneser", "subsets of 0", f"{U}.kneser(setSize: 4, subsetSize: 0)", lambda: kneser(4, 0))
    row("Kneser", "subsets larger than the set", f"{U}.kneser(setSize: 3, subsetSize: 4)", lambda: kneser(3, 4))
    # windmill
    for c, k, what in ((2, 3, ": the friendship graph F2 (butterfly)"), (3, 3, ": F3"), (3, 2, " is a star"), (2, 4, "")):
        row("Windmill", f"Wd({k}, {c}){what}", f"{U}.windmill(cliqueCount: {c}, cliqueVertexCount: {k})",
            lambda c=c, k=k: windmill(c, k), family="windmill", args=(c, k))
    row("Windmill", "directed: both arcs", f"{C}.windmill(cliqueCount: 2, cliqueVertexCount: 3)",
        lambda: windmill(2, 3, True), family="windmill", args=(2, 3), directed=True)
    row("Windmill", "one clique", f"{U}.windmill(cliqueCount: 1, cliqueVertexCount: 3)", lambda: windmill(1, 3))
    row("Windmill", "cliques of 1", f"{U}.windmill(cliqueCount: 3, cliqueVertexCount: 1)", lambda: windmill(3, 1))
    # binomial tree
    for k in (0, 1, 2, 3):
        row("BinomialTree", f"B{k}: parent of v is v & (v − 1)", f"{U}.binomialTree(order: {k})",
            lambda k=k: binomial_tree(k), family="binomialTree", args=(k,))
    row("BinomialTree", "directed: parent → child", f"{C}.binomialTree(order: 3)", lambda: binomial_tree(3, True),
        family="binomialTree", args=(3,), directed=True)
    row("BinomialTree", "Tree.binomialTree", "Tree<Int>.binomialTree(order: 3)", lambda: tree_binomial(3),
        family="binomialTree", args=(3,))
    row("BinomialTree", "negative order", f"{U}.binomialTree(order: -1)", lambda: binomial_tree(-1))
    row("BinomialTree", "2^63 vertices overflow Int", f"{U}.binomialTree(order: 63)", lambda: binomial_tree(63))
    # full r-ary tree
    for r, n, what in ((2, 0, " is the null graph"), (2, 1, " is one vertex"), (2, 6, ": the last level partly filled"),
                       (3, 10, ""), (1, 4, " is the path P4")):
        row("FullRaryTree", f"r = {r}, n = {n}{what}", f"{U}.fullRaryTree(branchingFactor: {r}, vertexCount: {n})",
            lambda r=r, n=n: full_rary_tree(r, n), family="fullRaryTree", args=(r, n))
    row("FullRaryTree", "directed: parent → child", f"{C}.fullRaryTree(branchingFactor: 2, vertexCount: 6)",
        lambda: full_rary_tree(2, 6, True), family="fullRaryTree", args=(2, 6), directed=True)
    row("FullRaryTree", "Tree.fullRaryTree", "Tree<Int>.fullRaryTree(branchingFactor: 3, vertexCount: 7)",
        lambda: tree_full_rary(3, 7), family="fullRaryTree", args=(3, 7))
    row("FullRaryTree", "branching factor 0", f"{U}.fullRaryTree(branchingFactor: 0, vertexCount: 3)",
        lambda: full_rary_tree(0, 3))
    row("FullRaryTree", "negative count", f"{U}.fullRaryTree(branchingFactor: 2, vertexCount: -1)",
        lambda: full_rary_tree(2, -1))
    row("FullRaryTree", "Tree.fullRaryTree(0): a tree is never empty", "Tree<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0)",
        lambda: tree_full_rary(2, 0))
    # de Bruijn
    for m, n, what in ((2, 3, ": loops at 000 and 111"), (3, 1, ": every arc, loops included"), (1, 2, ": one word, one loop"),
                       (2, 1, "")):
        row("DeBruijn", f"B({m}, {n}){what}", f"{A}.deBruijn(alphabetSize: {m}, wordLength: {n})",
            lambda m=m, n=n: de_bruijn(m, n), family="deBruijn", args=(m, n), directed=True)
    row("DeBruijn", "DirectedPseudograph: the same arcs", f"{P}.deBruijn(alphabetSize: 2, wordLength: 2)",
        lambda: de_bruijn(2, 2), family="deBruijn", args=(2, 2), directed=True)
    row("DeBruijn", "empty alphabet", f"{A}.deBruijn(alphabetSize: 0, wordLength: 2)", lambda: de_bruijn(0, 2))
    row("DeBruijn", "empty words", f"{A}.deBruijn(alphabetSize: 2, wordLength: 0)", lambda: de_bruijn(2, 0))
    # Kautz
    for s_, L, what in ((2, 3, ": 010 and 101"), (3, 2, ""), (3, 1, " is the complete digraph on 3"), (4, 2, "")):
        row("Kautz", f"words of {L} over {s_} letters{what}", f"{C}.kautz(alphabetSize: {s_}, wordLength: {L})",
            lambda s_=s_, L=L: kautz(s_, L), family="kautz", args=(s_, L), directed=True)
    row("Kautz", "one letter", f"{C}.kautz(alphabetSize: 1, wordLength: 2)", lambda: kautz(1, 2))
    row("Kautz", "empty words", f"{C}.kautz(alphabetSize: 3, wordLength: 0)", lambda: kautz(3, 0))
    # triangular lattice
    for m, n, what in ((1, 1, ": one triangle"), (1, 2, ": a rhombus"), (2, 3, ": odd n, odd rows one shorter"),
                       (2, 4, ""), (3, 2, ""), (0, 3, ": no rows, the null graph")):
        row("TriangularLattice", f"{m} × {n} triangles{what}", f"{U}.triangularLattice(rowCount: {m}, columnCount: {n})",
            lambda m=m, n=n: triangular_lattice(m, n), family="triangularLattice", args=(m, n))
    row("TriangularLattice", "directed: both arcs", f"{C}.triangularLattice(rowCount: 2, columnCount: 2)",
        lambda: triangular_lattice(2, 2, True), family="triangularLattice", args=(2, 2), directed=True)
    row("TriangularLattice", "negative rows", f"{U}.triangularLattice(rowCount: -1, columnCount: 2)",
        lambda: triangular_lattice(-1, 2))
    # hexagonal lattice
    for m, n, what in ((1, 1, " is C6"), (1, 2, ""), (2, 1, ""), (2, 2, ""), (1, 3, ": odd n drops the top of the last column"),
                       (3, 0, ": no columns, the null graph")):
        row("HexagonalLattice", f"{m} × {n} hexagons{what}", f"{U}.hexagonalLattice(rowCount: {m}, columnCount: {n})",
            lambda m=m, n=n: hexagonal_lattice(m, n), family="hexagonalLattice", args=(m, n))
    row("HexagonalLattice", "directed: both arcs", f"{C}.hexagonalLattice(rowCount: 1, columnCount: 2)",
        lambda: hexagonal_lattice(1, 2, True), family="hexagonalLattice", args=(1, 2), directed=True)
    row("HexagonalLattice", "negative columns", f"{U}.hexagonalLattice(rowCount: 1, columnCount: -1)",
        lambda: hexagonal_lattice(1, -1))
    # LCF
    for n, sh, r, what in ((6, [3, -3], 3, ": K3,3"), (8, [4], 8, ": the Wagner graph, chords repeated from both ends"),
                           (4, [2], 4, ": K4"), (5, [], 0, ": no chords, C5"), (6, [2], 1, ": one chord")):
        row("LCF", f"[{', '.join(map(str, sh))}]^{r} on {n}{what}", f"{U}.lcf(vertexCount: {n}, shifts: {sh}, repeatCount: {r})",
            lambda n=n, sh=sh, r=r: lcf(n, sh, r), family="lcf", args=(n, sh, r))
    row("LCF", "directed: both arcs", f"{C}.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3)",
        lambda: lcf(6, [3, -3], 3, True), family="lcf", args=(6, [3, -3], 3), directed=True)
    row("LCF", "a cycle of 2", f"{U}.lcf(vertexCount: 2, shifts: [1], repeatCount: 1)", lambda: lcf(2, [1], 1))
    row("LCF", "a shift that is a multiple of n is a self-loop", f"{U}.lcf(vertexCount: 6, shifts: [3, 6], repeatCount: 3)",
        lambda: lcf(6, [3, 6], 3))
    row("LCF", "negative repeat count", f"{U}.lcf(vertexCount: 6, shifts: [3], repeatCount: -1)", lambda: lcf(6, [3], -1))
    # named graphs
    for name in ("heawood", "moebiusKantor", "pappus", "desargues", "dodecahedral", "frucht"):
        n, sh, r = LCF_NAMED[name]
        row("NamedLCF", f"{name}: [{', '.join(map(str, sh))}]^{r} on {n}", f"{U}.{name}()",
            lambda name=name: lcf_named(name), family=name, args=())
    row("NamedLCF", "Heawood directed: both arcs", f"{C}.heawood()", lambda: lcf_named("heawood", True),
        family="heawood", args=(), directed=True)
    for name, fn in (("icosahedral", icosahedral), ("tutte", tutte), ("chvatal", chvatal),
                     ("hoffmanSingleton", hoffman_singleton)):
        row("NamedConstructions", f"{name}", f"{U}.{name}()", lambda fn=fn: fn(), family=name, args=(),
            full=name != "hoffmanSingleton")
    row("NamedConstructions", "icosahedral directed: both arcs", f"{C}.icosahedral()", lambda: icosahedral(True),
        family="icosahedral", args=(), directed=True)
    row("Kneser", "C(70, 35) vertices overflow Int", f"{U}.kneser(setSize: 70, subsetSize: 35)", lambda: kneser(70, 35))


# ---------------------------------------------------------------- catalog

HEADER = [
    "# NamedGraphs: case catalog",
    "",
    "Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0",
    "python3 Tests/Catalogs/NamedGraphs/ref.py`; `--write` regenerates this file, `--stress` adds the size",
    "sweeps). Every non-trap row is checked against NetworkX 3.7 under the numbering of `api.md` (exact edge",
    "set), against igraph 1.0 (exact where igraph numbers the same way, isomorphism for Petersen), and against",
    "the family's count and degree laws.",
    "",
    "Conventions:",
    "",
    "* `U` rows use `UndirectedAdjacencyList<Int>`, `C` rows `CompressedSparseRow`; the Representations group",
    "  repeats one family on the other conformers. Every factory gives the same vertices and edges on every",
    "  conformer of the same kind.",
    "* `E [u–v, …]` is `edges` in order: undirected edges are `UndirectedEdge(u, v)` with `u < v`, sorted",
    "  lexicographically; directed edges `u→v` are in row-major order. The order is part of the contract",
    "  (it is the insertion order on the adjacency lists, and CSR builds from it in one pass).",
    "* `deg` is the degree of each vertex in order; `out` / `in` the out- and in-degrees.",
    "* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`).",
    "",
    "| ID | Group | Case | Call | Expected |",
    "|---|---|---|---|---|",
]


def render():
    lines = list(HEADER)
    for i, (group, case, call, expected) in enumerate(ROWS, 1):
        lines.append(f"| NG-{i:03d} | {group} | {case} | `{call}` | {expected} |")
    return "\n".join(lines) + "\n"


def stress():
    count = 0
    for directed in (False, True):
        for n in range(0, 25):
            for fam, fn in (("complete", complete), ("path", path), ("empty", empty)):
                check(fam, (n,), directed, fn(n, directed)); count += 1
            if n >= 3:
                check("cycle", (n,), directed, cycle(n, directed)); count += 1
            if n >= 1:
                check("star", (n,), directed, star(n, directed)); count += 1
            if n >= 4 and not directed:
                check("wheel", (n,), False, wheel(n)); count += 1
        for a in range(0, 7):
            for b in range(0, 7):
                check("completeBipartite", (a, b), directed, complete_bipartite(a, b, directed)); count += 1
        for d in range(0, 9):
            check("hypercube", (d,), directed, hypercube(d, directed)); count += 1
        for dims in itertools.chain(([a] for a in range(0, 8)),
                                    ([a, b] for a in range(0, 7) for b in range(0, 7)),
                                    ([a, b, c] for a in range(1, 5) for b in range(1, 5) for c in range(1, 5))):
            for per in (False, True):
                check("grid", (dims, per), directed, grid(dims, per, directed)); count += 1
        for n in range(0, 12):
            check("ladder", (n,), directed, ladder(n, directed)); count += 1
            if n >= 3:
                check("circularLadder", (n,), directed, circular_ladder(n, directed)); count += 1
            for p in range(0, 5):
                if n >= 2:
                    check("barbell", (n, p), directed, barbell(n, p, directed)); count += 1
                    check("lollipop", (n, p), directed, lollipop(n, p, directed)); count += 1
            for r in range(1, n + 1):
                check("turan", (n, r), directed, turan(n, r, directed)); count += 1
        for sizes in itertools.chain(([a] for a in range(0, 5)), itertools.product(range(0, 4), repeat=2),
                                     itertools.product(range(0, 4), repeat=3)):
            sizes = list(sizes)
            check("completeMultipartite", (sizes,), directed, complete_multipartite(sizes, directed)); count += 1
        for r in range(0, 5):
            for h in range(0, 5):
                check("balancedTree", (r, h), directed, balanced_tree(r, h, directed)); count += 1
    return count


def main():
    build_rows()
    text = render()
    path_ = os.path.join(HERE, "cases.md")
    if "--write" in sys.argv:
        open(path_, "w").write(text)
        print(f"wrote {len(ROWS)} rows to cases.md")
    else:
        current = open(path_).read() if os.path.exists(path_) else ""
        if current != text:
            print("cases.md differs from the model (run with --write)")
            sys.exit(1)
        print(f"cases.md: {len(ROWS)} rows agree with the model, NetworkX and igraph")
    if "--stress" in sys.argv:
        print(f"stress: {stress()} family/size/direction combinations agree with NetworkX and igraph")


if __name__ == "__main__":
    main()
