"""Community detection beyond the deterministic models of scripts/differential.py (CommunityExtras in
Differential/Sources/GrafluentDifferential/CommunityExtras.swift).

* Leiden (modularity, unweighted and |w|; the constant Potts model at γ = 0.1): every community
  connected (weakly, directed), and node optimal for the quality by its definition (no vertex
  gains by moving alone to another community or to one of its own, beyond 1e-9 relative); the
  reported modularity and Potts value equal the definition; and, both being randomized heuristics,
  the best modularity of five library runs must not be below all five of igraph's (by more than
  LEIDEN_SLACK)
  community_leiden (undirected, modularity, run to convergence) or NetworkX's leiden_communities
  (directed).
* Louvain's levels end with louvainCommunities() and coarsen one another (checked library-side).
* Kernighan–Lin from the split {0 ..< n/2}, {n/2 ..< n}: equal to NetworkX's
  kernighan_lin_bisection with that partition (loops dropped), unweighted and with |w|.
* k-clique communities for k = 3, 4: equal to NetworkX's k_clique_communities as sets.
* Asynchronous fluid communities (k = 2, connected graphs): a partition into at most two.
* Walktrap (t = 4, n ≤ 60): the modularity of the chosen cut equal (to 1e-9) to that of
  `walktrap_model`, a dense model of the definition that recomputes every Δσ from the walk vectors,
  unless two candidate merges came within 1e-9 of each other (rounding may then order them either way);
  how often the partitions differ at equal modularity, and how often igraph's community_walktrap
  differs (its merges use stale Δσ values for communities next to only one of the merged pair, so
  its dendrogram can differ), are counted.
* Spectral clustering: `planted_partition_case(case)` derives a planted partition from the case alone
  (a stable hash seeds it): 2 to 4 blocks of 10 to 40 vertices, each pair inside a block an edge
  with probability 0.7 and across blocks 0.002, vertices shuffled, redrawn until every vertex has at
  least three neighbours in its block and three times as many as outside; and the k-means++ seed.
  The clustering into the planted count must match the planted labels: adjusted Rand index 1.
"""

import json
import random
import zlib

import networkx as nx
import igraph
import numpy as np

# Both are heuristics: a local optimum a little below every reference run is not a disagreement.
LEIDEN_SLACK = 0.005
COVERED = {"leiden": 0, "leiden best below the reference's best": 0, "leiden best above the reference's best": 0, "kernighan-lin": 0, "k-clique": 0, "walktrap": 0, "walktrap partitions differ": 0, "walktrap modularity differs from igraph's": 0, "walktrap near ties (not compared)": 0, "spectral clusterings": 0}


def planted_partition_case(case):
    rng = random.Random(zlib.crc32(json.dumps(["spectral", case["n"], case["edges"]]).encode()))
    clusters = rng.randint(2, 4)
    sizes = [rng.randint(10, 40) for _ in range(clusters)]
    n = sum(sizes)
    labels = [b for b, size in enumerate(sizes) for _ in range(size)]
    order = list(range(n))
    rng.shuffle(order)
    planted = [0] * n
    for i, v in enumerate(order):
        planted[v] = labels[i]
    while True:
        edges = []
        inside, across = [0] * n, [0] * n
        for u in range(n):
            for v in range(u + 1, n):
                same = planted[u] == planted[v]
                if rng.random() < (0.7 if same else 0.002):
                    edges.append([u, v])
                    for x in (u, v):
                        if same:
                            inside[x] += 1
                        else:
                            across[x] += 1
        # Clearly separated: every vertex has at least three neighbours in its block and three times
        # as many there as outside.
        if all(inside[v] >= 3 and inside[v] >= 3 * across[v] for v in range(n)):
            break
    return {"n": n, "edges": edges, "clusters": clusters, "seed": rng.randrange(1 << 63), "planted": planted}


def adjusted_rand_index(a, b):
    """Hubert and Arabie's adjusted Rand index of two labelings."""
    from collections import Counter
    n = len(a)
    if n < 2:
        return 1.0
    pairs = Counter(zip(a, b))
    comb = lambda x: x * (x - 1) / 2  # noqa: E731
    index = sum(comb(c) for c in pairs.values())
    rows = sum(comb(c) for c in Counter(a).values())
    cols = sum(comb(c) for c in Counter(b).values())
    expected = rows * cols / comb(n)
    maximum = (rows + cols) / 2
    return 1.0 if maximum == expected else (index - expected) / (maximum - expected)


def walktrap_model(n, ends, w, steps=4):
    """Walktrap by the definition, dense: Ward merges of adjacent communities by least Δσ computed
    from the walk vectors each time (no Lance–Williams), ties to the least pair of community numbers
    (vertices 0 ..< n, the k-th merge n + k); the cut of greatest modularity, the earliest on a tie."""
    A = np.zeros((n, n))
    loops = np.zeros(n)
    for (u, v), x in zip(ends, w):
        if u == v:
            loops[u] += x
        else:
            A[u, v] += x
            A[v, u] += x
    adjacent = [set() for _ in range(n)]
    for (u, v) in ends:
        if u != v:
            adjacent[u].add(v)
            adjacent[v].add(u)
    sums = A.sum(1)
    counts = np.array([len(adjacent[v]) for v in range(n)])
    added = np.where((counts > 0) & (sums > 0), sums / np.maximum(counts, 1), 1.0)
    B = A + np.diag(added)
    d = B.sum(1)
    P = np.linalg.matrix_power(B / d[:, None], steps)
    X = P / np.sqrt(d)[None, :]
    vec = {v: X[v] for v in range(n)}
    size = {v: 1.0 for v in range(n)}
    members = {v: [v] for v in range(n)}
    adj = {v: set(adjacent[v]) for v in range(n)}
    m2 = sum(w) * 2
    def modularity(groups):
        if m2 == 0:
            return 0.0
        q = 0.0
        for g in groups:
            s = set(g)
            inside = sum(x for (u, v), x in zip(ends, w) if u in s and v in s)
            deg = sum(x * ((u in s) + (v in s)) for (u, v), x in zip(ends, w))
            q += inside / (m2 / 2) - (deg / m2) ** 2
        return q
    best = (modularity(members.values()), [list(g) for g in members.values()])
    nxt = n
    tied = False
    while True:
        cands = []
        for a in adj:
            for b in adj[a]:
                if a < b:
                    r = ((vec[a] - vec[b]) ** 2).sum()
                    cands.append((size[a] * size[b] / (size[a] + size[b]) * r / n, a, b))
        if not cands:
            break
        cands.sort()
        if len(cands) > 1 and cands[1][0] - cands[0][0] <= 1e-9 * max(cands[0][0], 1e-300):
            tied = True
        _, a, b = cands[0]
        c = nxt
        nxt += 1
        vec[c] = (size[a] * vec[a] + size[b] * vec[b]) / (size[a] + size[b])
        size[c] = size[a] + size[b]
        members[c] = members.pop(a) + members.pop(b)
        adj[c] = (adj.pop(a) | adj.pop(b)) - {a, b}
        for x in adj[c]:
            adj[x] -= {a, b}
            adj[x].add(c)
        q = modularity(members.values())
        if q > best[0]:
            best = (q, [list(g) for g in members.values()])
    labels = [0] * n
    for i, g in enumerate(best[1]):
        for v in g:
            labels[v] = i
    return labels, best[0], tied


def canonical(labels):
    seen = {}
    return [seen.setdefault(x, len(seen)) for x in labels]


def quality(n, directed, ends, w, labels, potts, gamma):
    """m · modularity or the constant Potts model, by the definition."""
    m = sum(w)
    inside = sum(x for (a, b), x in zip(ends, w) if labels[a] == labels[b])
    groups = {}
    if potts:
        for v in range(n):
            groups[labels[v]] = groups.get(labels[v], 0) + 1
        scale = gamma if directed else gamma / 2
        return inside - sum(scale * s * s for s in groups.values())
    if m == 0:
        return 0.0
    out, into = {}, {}
    for (a, b), x in zip(ends, w):
        out[labels[a]] = out.get(labels[a], 0) + x
        into[labels[b]] = into.get(labels[b], 0) + x
        if not directed:
            out[labels[b]] = out.get(labels[b], 0) + x
            into[labels[a]] = into.get(labels[a], 0) + x
    scale = gamma / m if directed else gamma / (4 * m)
    return inside - sum(scale * out.get(c, 0) * into.get(c, 0) for c in set(labels))


def connected_parts(n, ends, labels):
    parent = list(range(n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    for a, b in ends:
        if labels[a] == labels[b]:
            parent[find(a)] = find(b)
    return len({find(v) for v in range(n)})


def node_optimal(n, directed, ends, w, labels, potts, gamma):
    """The first vertex that gains by moving alone, or None. Gains by the incremental formula,
    checked against the definition when one exceeds the tolerance."""
    h = quality(n, directed, ends, w, labels, potts, gamma)
    tolerance = 1e-9 * max(1.0, abs(h))
    k = max(labels) + 1 if labels else 0
    for v in range(n):
        for target in range(k + 1):
            if target == labels[v]:
                continue
            moved = list(labels)
            moved[v] = target
            if quality(n, directed, ends, w, moved, potts, gamma) > h + tolerance:
                return v
    return None


def compare_community_extras(case, mine, problems):
    n, directed = case["n"], case["directed"]
    ends = [(u, v) for u, v, _ in case["edges"]]
    unit = [1.0] * len(ends)
    absw = [float(abs(x)) for _, _, x in case["edges"]]
    if not mine.get("louvainLevelsAgree", True):
        problems.append("louvainPartitions() does not end with louvainCommunities() or does not coarsen")
    planted = case.get("plantedPartition")
    if planted is not None:
        COVERED["spectral clusterings"] += 1
        labels = mine.get("spectralClusters")
        if labels is None:
            problems.append("spectralClustering threw on the planted partition")
        else:
            ari = adjusted_rand_index(labels, planted["planted"])
            if ari < 1 - 1e-12:
                problems.append(f"spectralClustering: adjusted Rand index {ari} on {planted['clusters']} planted blocks")
    small = n <= 30
    for key, w, potts, gamma in [("leiden", unit, False, 1.0), ("weightedLeiden", absw, False, 1.0), ("leidenPotts", unit, True, 0.1)]:
        labels = mine[key]
        if sorted(set(labels)) != list(range(len(set(labels)))) or len(labels) != n:
            problems.append(f"{key}: not a partition: {labels}")
            continue
        parts = connected_parts(n, ends, labels)
        if parts != len(set(labels)):
            problems.append(f"{key}: a community is disconnected: {labels}")
        if small:
            v = node_optimal(n, directed, ends, w, labels, potts, gamma)
            if v is not None:
                problems.append(f"{key}: vertex {v} gains by moving alone: {labels}")
    COVERED["leiden"] += 1
    h = quality(n, directed, ends, unit, mine["leiden"], False, 1.0)
    m = len(ends)
    q = h / m if m else 0.0
    if abs(q - mine["leidenModularity"]) > 1e-9:
        problems.append(f"leiden modularity: library {mine['leidenModularity']}, definition {q}")
    potts = quality(n, directed, ends, unit, mine["leidenPotts"], True, 0.1)
    if abs(potts - mine["leidenPottsQuality"]) > 1e-9 * max(1.0, abs(potts)):
        problems.append(f"constantPottsModel: library {mine['leidenPottsQuality']}, definition {potts}")
    if m > 0:
        # Both are randomized: the library's best of five runs against the reference's five.
        refs = []
        if directed:
            H = nx.DiGraph()
            H.add_nodes_from(range(n))
            H.add_edges_from(ends)
            for seed in range(5):
                theirs = nx.community.leiden_communities(H, metric="modularity", weight=None, seed=seed)
                refs.append(nx.community.modularity(H, theirs, weight=None))
        else:
            G = igraph.Graph(n=n, edges=ends)
            for seed in range(5):
                rng = random.Random(seed)
                igraph.set_random_number_generator(rng)
                refs.append(G.modularity(G.community_leiden(objective_function="modularity", n_iterations=-1).membership))
            igraph.set_random_number_generator(random)
        best = mine["leidenBestModularity"]
        if best < min(refs) - LEIDEN_SLACK:
            problems.append(f"leiden: the best of five runs, {best}, is below every reference run {refs} by more than {LEIDEN_SLACK}")
        if best < max(refs) - 1e-9:
            COVERED["leiden best below the reference's best"] += 1
        elif best > max(refs) + 1e-9:
            COVERED["leiden best above the reference's best"] += 1
    if directed:
        return
    loopless = [(u, v) for u, v in ends if u != v]
    if n >= 2:
        for key, weighted in [("kernighanLin", False), ("weightedKernighanLin", True)]:
            H = nx.Graph()
            H.add_nodes_from(range(n))
            for (u, v), x in zip(ends, absw):
                if u != v:
                    H.add_edge(u, v, weight=x)
            a, b = set(range(n // 2)), set(range(n // 2, n))
            first, second = nx.community.kernighan_lin_bisection(H, partition=(a, b), weight="weight" if weighted else None)
            lab = [0 if v in first else 1 for v in range(n)]
            if mine[key] != canonical(lab):
                problems.append(f"{key}: library {mine[key]}, NetworkX {canonical(lab)}")
        COVERED["kernighan-lin"] += 1
    S = nx.Graph()
    S.add_nodes_from(range(n))
    S.add_edges_from(loopless)
    for key, k in [("kClique3", 3), ("kClique4", 4)]:
        theirs = {frozenset(c) for c in nx.community.k_clique_communities(S, k)}
        ours = {frozenset(c) for c in mine[key]}
        if ours != theirs:
            problems.append(f"{key}: library {sorted(map(sorted, ours))}, NetworkX {sorted(map(sorted, theirs))}")
    COVERED["k-clique"] += 1
    fluid = mine.get("fluid")
    if fluid is not None and (len(fluid) != n or len(set(fluid)) > 2):
        problems.append(f"fluid: not a partition into at most two: {fluid}")
    if n <= 60:
        labels, q, tied = walktrap_model(n, ends, unit)
        if tied:
            COVERED["walktrap near ties (not compared)"] += 1
        elif abs(mine["walktrapModularity"] - q) > 1e-9:
            problems.append(f"walktrap modularity: library {mine['walktrapModularity']}, model {q}")
        elif canonical(labels) != mine["walktrap"]:
            COVERED["walktrap partitions differ"] += 1
        COVERED["walktrap"] += 1
        if len(loopless) == len(ends) and n >= 2 and ends:
            G = igraph.Graph(n=n, edges=ends)
            ref = G.modularity(G.community_walktrap(steps=4).as_clustering().membership)
            if abs(mine["walktrapModularity"] - ref) > 1e-9:
                COVERED["walktrap modularity differs from igraph's"] += 1
