"""Spanning arborescences, branchings and Steiner trees against NetworkX, for differential.py.

Arborescences (directed cases): every weight must equal NetworkX's `minimum_branching` and
`maximum_branching`, and the spanning optima NetworkX's `maximum_branching` gives under weights
M − w (minimum) or M + w (maximum), M = 2 Σ|w| + 1: one more edge outweighs any difference of
weights, so the best branching spans whenever a spanning arborescence exists (nil otherwise).
NetworkX 3.7's own `minimum_spanning_arborescence` and `maximum_spanning_arborescence` raise "No
minimum spanning arborescence in G" on some graphs that have one (seen with zero and tied weights,
for example Differential/Failures cases of seed 801680861), so they are not the reference. Rooted
at r, the graph without the edges into r is asked, whose spanning arborescences are exactly those
rooted at r. Every returned edge list must be a
branching of the claimed weight (spanning, and from r, where it should be). Ties cannot change a
weight, so weights are compared exactly.

Steiner trees (undirected cases, weights |w|, terminals the sources and the target): both methods
must return a tree over the case's edges that joins every terminal, whose leaves are terminals,
of the claimed weight, and no heavier than the minimum spanning tree of the terminals' distance
graph (the bound both methods guarantee, at most 2(1 − 1/t) times the optimum); nil exactly when
two terminals are in different components. Two terminals: the shortest-path distance. NetworkX's
`steiner_tree` weights are not compared, since ties change them.
"""

import networkx as nx


def _digraph(case, skip_into=None):
    G = nx.DiGraph()
    G.add_nodes_from(range(case["n"]))
    for u, v, w in case["edges"]:
        if u != v and v != skip_into:
            G.add_edge(u, v, weight=w)
    return G


def _spanning_weight(G, n, maximum):
    """The optimum spanning arborescence's weight through `maximum_branching` (see above)."""
    big = 2 * sum(abs(d["weight"]) for _, _, d in G.edges(data=True)) + 1
    H = nx.DiGraph()
    H.add_nodes_from(G)
    for u, v, d in G.edges(data=True):
        H.add_edge(u, v, weight=big + d["weight"] if maximum else big - d["weight"], original=d["weight"])
    B = nx.maximum_branching(H, attr="weight", preserve_attrs=True)
    if B.number_of_edges() != n - 1 or n == 0:
        return None
    return sum(d["original"] for _, _, d in B.edges(data=True))


def _branching_problems(case, edges, weight, name, spanning, root=None):
    problems = []
    n, es = case["n"], case["edges"]
    if edges != sorted(edges) or sum(es[k][2] for k in edges) != weight:
        problems.append(f"{name}: edges {edges} are unsorted or do not weigh {weight}")
    parent = [-1] * n
    for k in edges:
        u, v, _ = es[k]
        if u == v or parent[v] != -1:
            problems.append(f"{name}: edge {k} is a loop or the second into {v}")
            return problems
        parent[v] = u
    for start in range(n):
        x, steps = start, 0
        while parent[x] >= 0 and steps <= n:
            x, steps = parent[x], steps + 1
        if steps > n:
            problems.append(f"{name}: a cycle through {start}")
            return problems
        if root is not None and x != root:
            problems.append(f"{name}: {start} does not hang from {root}")
            return problems
    if spanning and len(edges) != n - 1:
        problems.append(f"{name}: {len(edges)} edges do not span {n} vertices")
    return problems


def compare_arborescences(case, mine):
    problems = []
    G = _digraph(case)
    root = case["sources"][0]
    R = _digraph(case, skip_into=root)
    expected = {
        "minimum": _spanning_weight(G, case["n"], False),
        "maximum": _spanning_weight(G, case["n"], True),
        "rootedMinimum": _spanning_weight(R, case["n"], False),
        "rootedMaximum": _spanning_weight(R, case["n"], True),
        "minimumBranching": round(nx.minimum_branching(G, attr="weight").size(weight="weight")),
        "maximumBranching": round(nx.maximum_branching(G, attr="weight").size(weight="weight")),
    }
    for key, theirs in expected.items():
        if mine.get(key) != theirs:
            problems.append(f"{key}: library {mine.get(key)}, NetworkX {theirs}")
        elif theirs is not None:
            spanning = not key.endswith("Branching")
            problems += _branching_problems(case, mine[key + "Edges"], theirs, key, spanning,
                                            root if key.startswith("rooted") else None)
    return problems


def compare_steiner(case, mine):
    problems = []
    n, es = case["n"], case["edges"]
    terminals = mine["terminals"]
    G = nx.Graph()
    G.add_nodes_from(range(n))
    for u, v, w in es:
        if u != v and (not G.has_edge(u, v) or abs(w) < G[u][v]["weight"]):
            G.add_edge(u, v, weight=abs(w))
    component = nx.node_connected_component(G, terminals[0])
    connected = all(t in component for t in terminals)
    # The minimum spanning tree of the terminals' distance graph.
    D = nx.Graph()
    D.add_nodes_from(terminals)
    if connected:
        for t in terminals:
            lengths = nx.single_source_dijkstra_path_length(G, t)
            for s in terminals:
                if s != t:
                    D.add_edge(t, s, weight=lengths[s])
    bound = nx.minimum_spanning_tree(D).size(weight="weight") if connected else None
    for name in ("mehlhorn", "kou"):
        weight, edges = mine.get(name), mine.get(name + "Edges")
        if (weight is None) != (not connected):
            problems.append(f"steiner {name}: {weight} for terminals {terminals}, connected {connected}")
            continue
        if weight is None:
            continue
        if edges != sorted(edges) or sum(abs(es[k][2]) for k in edges) != weight:
            problems.append(f"steiner {name}: edges {edges} are unsorted or do not weigh {weight}")
        T = nx.MultiGraph()
        T.add_nodes_from(terminals)
        T.add_edges_from((es[k][0], es[k][1]) for k in edges)
        if any(es[k][0] == es[k][1] for k in edges) or not nx.is_tree(T):
            problems.append(f"steiner {name}: {edges} is not a tree over the terminals {terminals}")
        elif any(d == 1 and v not in terminals for v, d in T.degree()):
            problems.append(f"steiner {name}: a leaf that is not a terminal in {edges}")
        if weight > bound + 1e-9:
            problems.append(f"steiner {name}: {weight} above the distance-graph tree {bound}")
        if len(terminals) == 2 and weight != nx.dijkstra_path_length(G, terminals[0], terminals[1]):
            problems.append(f"steiner {name}: {weight} is not the distance between {terminals}")
    return problems
