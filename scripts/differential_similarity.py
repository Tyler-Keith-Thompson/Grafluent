"""The Similarity section of scripts/differential.py.

The link-prediction measures on the case's simple undirected graph (a directed case's arcs as
edges, loops dropped, repeated pairs merged) against NetworkX (common_neighbors,
jaccard_coefficient, adamic_adar_index, resource_allocation_index, preferential_attachment) and
igraph (similarity_jaccard, similarity_dice and similarity_inverse_log_weighted with loops=False);
the cosine (Salton) index, which neither library has, against its formula over NetworkX's neighbor
sets. Counts are compared exactly, ratios and sums to 1e-12 relative. `consistent` says the
library's one-pair spellings equal its many-pair spellings exactly.

SimRank (C = 0.8) on the graph as given, loops kept (a loop's vertex is its own in-neighbor),
directed over in-neighbors: against a dense iteration of the definition run to a change below
1e-14 (to 1e-9), and against NetworkX's simrank_similarity (to 1e-4, as its stopping rule is
relative). Only for n ≤ 60, as the library's section answers.
"""

import networkx as nx
import numpy as np
import igraph

COVERED = {"pairs": 0, "pairs with common neighbors": 0, "simrank matrices": 0}


def close(a, b, rel=1e-12):
    return a == b or abs(a - b) <= rel * max(abs(a), abs(b), 1e-300)


def simrank_reference(n, edges, directed, c):
    """The SimRank fixed point by the definition, iterated densely until the largest change is
    below 1e-14."""
    a = np.zeros((n, n))
    for u, v, _ in edges:
        a[u, v] = 1
        if not directed:
            a[v, u] = 1
    counts = a.sum(axis=0)
    w = a / np.where(counts == 0, 1, counts)
    s = np.eye(n)
    for _ in range(100000):
        nxt = c * (w.T @ s @ w)
        np.fill_diagonal(nxt, 1.0)
        if np.max(np.abs(nxt - s)) < 1e-14:
            return nxt
        s = nxt
    return s


def compare_similarity(case, mine):
    problems = []
    if mine is None:
        return ["no similarity answers"]
    n = case["n"]
    U = nx.Graph()
    U.add_nodes_from(range(n))
    U.add_edges_from((u, v) for u, v, _ in case["edges"] if u != v)
    pairs = [tuple(p) for p in mine["pairs"]]
    if not mine["consistent"]:
        problems.append("the one-pair spellings disagree with the many-pair spellings")
    COVERED["pairs"] += len(pairs)
    common = [len(list(nx.common_neighbors(U, u, v))) for u, v in pairs]
    COVERED["pairs with common neighbors"] += sum(1 for x in common if x)
    checks = [
        ("commonNeighborCounts", mine["common"], common, True),
        ("jaccardCoefficients", mine["jaccard"], [p for _, _, p in nx.jaccard_coefficient(U, pairs)], False),
        ("adamicAdarIndices", mine["adamicAdar"], [p for _, _, p in nx.adamic_adar_index(U, pairs)], False),
        ("resourceAllocationIndices", mine["resourceAllocation"], [p for _, _, p in nx.resource_allocation_index(U, pairs)], False),
        ("preferentialAttachmentScores", mine["preferentialAttachment"], [p for _, _, p in nx.preferential_attachment(U, pairs)], True),
    ]
    cosine = []
    for (u, v), c in zip(pairs, common):
        du, dv = U.degree(u), U.degree(v)
        cosine.append(0.0 if du == 0 or dv == 0 else c / (du * dv) ** 0.5)
    checks.append(("cosineSimilarities (formula)", mine["cosine"], cosine, False))
    I = igraph.Graph(n=n, edges=[(u, v) for u, v in U.edges()])
    if pairs:
        checks.append(("jaccardCoefficients (igraph)", mine["jaccard"], I.similarity_jaccard(pairs=pairs, loops=False), False))
        checks.append(("diceCoefficients (igraph)", mine["dice"], I.similarity_dice(pairs=pairs, loops=False), False))
        weighted = I.similarity_inverse_log_weighted()
        checks.append(("adamicAdarIndices (igraph)", mine["adamicAdar"], [weighted[u][v] for u, v in pairs], False))
    for name, ours, theirs, exact in checks:
        if len(ours) != len(theirs):
            problems.append(f"{name}: {len(ours)} scores, reference {len(theirs)}")
            continue
        bad = [k for k, (a, b) in enumerate(zip(ours, theirs)) if (a != b if exact else not close(a, b))]
        if bad:
            k = bad[0]
            problems.append(f"{name}{pairs[k]}: library {ours[k]}, reference {theirs[k]} ({len(bad)} pairs differ)")

    if n <= 60:
        ours = mine.get("simRank")
        if ours is None:
            problems.append("simRankSimilarity did not converge")
            return problems
        COVERED["simrank matrices"] += 1
        directed = case["directed"]
        reference = simrank_reference(n, case["edges"], directed, 0.8)
        worst = max((abs(ours[a * n + b] - reference[a, b]), a, b) for a in range(n) for b in range(n))
        if worst[0] > 1e-9:
            _, a, b = worst
            problems.append(f"simRank({a}, {b}): library {ours[a * n + b]}, definition {reference[a, b]}")
        G = nx.DiGraph() if directed else nx.Graph()
        G.add_nodes_from(range(n))
        G.add_edges_from((u, v) for u, v, _ in case["edges"])
        theirs = nx.simrank_similarity(G, importance_factor=0.8, max_iterations=100000, tolerance=1e-10)
        worst = max((abs(ours[a * n + b] - theirs[a][b]), a, b) for a in range(n) for b in range(n))
        if worst[0] > 1e-4:
            _, a, b = worst
            problems.append(f"simRank({a}, {b}): library {ours[a * n + b]}, NetworkX {theirs[a][b]}")
    return problems
