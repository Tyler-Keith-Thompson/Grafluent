"""The isomorphism section of scripts/differential.py.

Graph edit distance on small cases (n <= 6, at most 10 edges, as the library's section answers):
the case's graph against its partner (Differential/Sources/GrafluentDifferential/Isomorphism.swift,
`editPartner`), at unit costs and with vertex colours v mod 2, against NetworkX's
graph_edit_distance (node_match on the colour for the second). The library must also report its
paths as consistent (each costs what its operations add up to, edges substituted only between
images).

With a self-loop in either graph NetworkX can substitute an edge by one whose ends are not the
images of its ends (a loop for a non-loop), and then reports less; those cases are compared with
brute force over every partial injection instead, and NetworkX's value must not exceed it.
"""

import itertools

import networkx as nx

COVERED = {"edit distances": 0, "nonzero": 0, "with self-loops (brute force)": 0, "NetworkX below the distance with self-loops": 0}


def brute_force(directed, n, g_edges, m, h_edges, colored):
    """The unit-cost distance over every partial injection; colours v mod 2 when `colored`."""
    def pairs(edges):
        count = {}
        for u, v in edges:
            key = (u, v) if directed or u <= v else (v, u)
            count[key] = count.get(key, 0) + 1
        return count
    pg, ph = pairs(g_edges), pairs(h_edges)
    best = None
    for k in range(min(n, m) + 1):
        for kept in itertools.combinations(range(n), k):
            for images in itertools.permutations(range(m), k):
                f = [-1] * n
                for u, x in zip(kept, images):
                    f[u] = x
                used = set(images)
                cost = (n - k) + (m - k) + sum(1 for u, x in zip(kept, images) if colored and u % 2 != x % 2)
                for a in range(n):
                    for b in range(n) if directed else range(a, n):
                        mine = pg.get((a, b), 0)
                        if f[a] >= 0 and f[b] >= 0:
                            x, y = f[a], f[b]
                            key = (x, y) if directed or x <= y else (y, x)
                            cost += abs(mine - ph.get(key, 0))
                        else:
                            cost += mine
                cost += sum(1 for u, v in h_edges if u not in used or v not in used)
                if best is None or cost < best:
                    best = cost
    return best


def partner(directed, n, edges):
    m = max(n - 1, 1)
    kept = []

    def has(a, b):
        return [a, b] in kept or (not directed and [b, a] in kept)

    for k, (u, v, _) in enumerate(edges):
        if k % 3 == 2:
            continue
        a, b = u % m, v % m
        if not has(a, b):
            kept.append([a, b])
    if m >= 2 and not has(0, m - 1):
        kept.append([0, m - 1])
    return m, kept


def compare_isomorphism(case, mine):
    n, edges, directed = case["n"], case["edges"], case["directed"]
    if n > 6 or len(edges) > 10:
        return []
    if mine is None or mine.get("editDistance") is None:
        return ["no edit distance answers"]
    problems = []
    m, kept = partner(directed, n, edges)
    kind = nx.DiGraph if directed else nx.Graph
    G, H = kind(), kind()
    G.add_nodes_from((v, {"c": v % 2}) for v in range(n))
    G.add_edges_from((u, v) for u, v, _ in edges)
    H.add_nodes_from((v, {"c": v % 2}) for v in range(m))
    H.add_edges_from((a, b) for a, b in kept)
    plain = nx.graph_edit_distance(G, H)
    colored = nx.graph_edit_distance(G, H, node_match=lambda a, b: a["c"] == b["c"])
    if any(u == v for u, v, _ in edges) or any(a == b for a, b in kept):
        g_edges = [(u, v) for u, v, _ in edges]
        exact = brute_force(directed, n, g_edges, m, kept, False), brute_force(directed, n, g_edges, m, kept, True)
        if plain > exact[0] or colored > exact[1]:
            problems.append(f"NetworkX {plain}, {colored} above brute force {exact}")
        COVERED["with self-loops (brute force)"] += 1
        COVERED["NetworkX below the distance with self-loops"] += (plain < exact[0]) + (colored < exact[1])
        plain, colored = exact
    if mine["editDistance"] != plain:
        problems.append(f"graphEditDistance {mine['editDistance']}, NetworkX {plain}")
    if mine["coloredEditDistance"] != colored:
        problems.append(f"coloured graphEditDistance {mine['coloredEditDistance']}, NetworkX {colored}")
    if not mine["consistent"]:
        problems.append("an edit path's operations do not add up to its cost")
    COVERED["edit distances"] += 2
    COVERED["nonzero"] += (plain > 0) + (colored > 0)
    return problems
