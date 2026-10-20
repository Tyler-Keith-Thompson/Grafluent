"""Community detection beyond the deterministic models of scripts/differential.py (CommunityExtras in
Differential/Sources/GrafluentDifferential/CommunityExtras.swift).

* Leiden (modularity, unweighted and |w|; the constant Potts model at γ = 0.1): every community
  connected (weakly, directed), and node optimal for the quality by its definition (no vertex
  gains by moving alone to another community or to one of its own, beyond 1e-9 relative); the
  reported modularity and Potts value equal the definition; and, both being randomized heuristics,
  the best modularity of five library runs must not be below all five of igraph's (by more than
  LEIDEN_SLACK)
  community_leiden (undirected, modularity with self-loops in the degrees, run to convergence) or
  NetworkX's leiden_communities
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
* Infomap (10 trials, unweighted and |w|): a partition whose reported codeLength equals the map
  equation by its definition (`code_length`), and, on cases without self-loops (igraph counts a
  self-loop's flow differently), no longer than igraph's community_infomap code length by more
  than INFOMAP_SLACK relative; the exact partitions are not compared.
* Spectral clustering: `planted_partition_case(case)` derives a planted partition from the case alone
  (a stable hash seeds it): 2 to 4 blocks of 10 to 40 vertices, each pair inside a block an edge
  with probability 0.7 and across blocks 0.002, vertices shuffled, redrawn until every vertex has at
  least three neighbours in its block and three times as many as outside; and the k-means++ seed.
  The clustering into the planted count must match the planted labels: adjusted Rand index 1.
"""

import json
import math
import random
import zlib

import networkx as nx
import igraph
import numpy as np

# Both are heuristics: a local optimum a little below every reference run is not a disagreement.
LEIDEN_SLACK = 0.005
# Both Infomaps are randomized greedy searches that can stop in different local optima (on small
# trees the gap reaches about 5%): the library's code length may exceed igraph's by this, relative.
INFOMAP_SLACK = 0.06
COVERED = {"infomap": 0, "infomap longer than igraph's": 0, "infomap shorter than igraph's": 0, "leiden": 0, "leiden best below the reference's best": 0, "leiden best above the reference's best": 0, "kernighan-lin": 0, "k-clique": 0, "walktrap": 0, "walktrap partitions differ": 0, "walktrap modularity differs from igraph's": 0, "walktrap near ties (not compared)": 0, "spectral clusterings": 0}


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


def canonical_labels(labels):
    """Labels renumbered by first appearance: equal exactly when the partitions are."""
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


def code_length(n, ends, w, labels):
    """The two-level map equation over the edges: flow d/2W at each vertex, w/2W along each edge
    each way, a self-loop twice in its vertex's degree and never leaving a module."""
    total = sum(w)
    if total == 0:
        return 0.0
    f = lambda x: x * math.log2(x) if x > 0 else 0.0
    p = [0.0] * n
    q = {}
    size = {}
    for (u, v), x in zip(ends, w):
        p[u] += x / (2 * total)
        p[v] += x / (2 * total)
        if labels[u] != labels[v]:
            q[labels[u]] = q.get(labels[u], 0.0) + x / (2 * total)
            q[labels[v]] = q.get(labels[v], 0.0) + x / (2 * total)
    for a in range(n):
        size[labels[a]] = size.get(labels[a], 0.0) + p[a]
    return (f(sum(q.values())) - 2 * sum(f(x) for x in q.values()) - sum(f(x) for x in p)
            + sum(f(q.get(c, 0.0) + size[c]) for c in size))


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
    # Hierarchical Leiden with a cap of 3, from the same seed as the plain run: level 0 is the
    # plain partition; levels and children are ranges; a child's vertices are inside its parent's
    # and the children of a split community cover it; every community is connected; the leaves
    # partition the vertices and name each vertex's final community.
    levels, parents, members, leaf_of = mine["hierarchicalLeidenLevels"], mine["hierarchicalLeidenParents"], mine["hierarchicalLeidenMembers"], mine["hierarchicalLeidenLeafOf"]
    count = len(levels)
    if not (len(parents) == len(members) == count):
        problems.append(f"hierarchicalLeiden: {count} levels, {len(parents)} parents, {len(members)} member lists")
    else:
        if n:
            level0 = members[: levels.count(0)]
            if canonical_labels(mine["leiden"]) != canonical_labels([next(i for i, c in enumerate(level0) if v in c) for v in range(n)]):
                problems.append(f"hierarchicalLeiden: level 0 {level0} is not leiden's {mine['leiden']}")
        if levels != sorted(levels) or any(l != 0 for l in levels[: levels.count(0)]):
            problems.append(f"hierarchicalLeiden: levels {levels} are not in order")
        children = {c: [d for d in range(count) if parents[d] == c] for c in range(count)}
        for c in range(count):
            vs = members[c]
            if vs != sorted(vs) or not vs:
                problems.append(f"hierarchicalLeiden: community {c} is {vs}")
            if connected_parts(len(vs), [(vs.index(a), vs.index(b)) for a, b in ends if a in vs and b in vs], [0] * len(vs)) != 1:
                problems.append(f"hierarchicalLeiden: community {c} is not connected: {vs}")
            p = parents[c]
            if p < 0:
                if levels[c] != 0:
                    problems.append(f"hierarchicalLeiden: community {c} on level {levels[c]} has no parent")
            elif levels[p] != levels[c] - 1 or not set(vs) <= set(members[p]):
                problems.append(f"hierarchicalLeiden: community {c} under {p}")
            kids = children[c]
            if kids:
                if kids != list(range(kids[0], kids[0] + len(kids))) or len(kids) < 2 or len(vs) <= 3:
                    problems.append(f"hierarchicalLeiden: community {c} of {len(vs)} has children {kids}")
                if sorted(v for d in kids for v in members[d]) != vs:
                    problems.append(f"hierarchicalLeiden: the children of {c} do not cover it")
        leaves = [c for c in range(count) if not children[c]]
        if sorted(v for c in leaves for v in members[c]) != list(range(n)):
            problems.append("hierarchicalLeiden: the leaves do not partition the vertices")
        if any(leaf_of[v] != c for c in leaves for v in members[c]):
            problems.append("hierarchicalLeiden: community(of:) disagrees with the leaves")
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
            # community_leiden(objective_function="modularity") weighs vertices by their degrees
            # without self-loops; modularity counts a loop twice in its vertex's degree, so the
            # degrees and 1 / 2m are passed instead. Its n_iterations=-1 can loop forever (an
            # iteration can report a change and leave the partition as it was), so iterations run
            # one at a time until the partition stops changing.
            degrees = [float(d) for d in G.degree()]
            for seed in range(5):
                rng = random.Random(seed)
                igraph.set_random_number_generator(rng)
                membership = None
                for _ in range(100):
                    last = membership
                    membership, _ = igraph.GraphBase.community_leiden(G, node_weights=degrees, resolution=1 / (2 * m), normalize_resolution=False, beta=0.01, initial_membership=membership, n_iterations=1)
                    if last is not None and canonical_labels(membership) == canonical_labels(last):
                        break
                refs.append(G.modularity(membership))
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
    for key, w in [("infomap", unit), ("weightedInfomap", absw)]:
        labels = mine.get(key)
        if labels is None:
            problems.append(f"{key}: no answer")
            continue
        if sorted(set(labels)) != list(range(len(set(labels)))) or len(labels) != n:
            problems.append(f"{key}: not a partition: {labels}")
            continue
        ours = mine[key + "CodeLength"]
        length = code_length(n, ends, w, labels)
        if abs(ours - length) > 1e-9:
            problems.append(f"{key} codeLength: library {ours}, definition {length}")
        # igraph counts a self-loop's flow differently, so code lengths are compared without them.
        if sum(w) == 0 or any(u == v for u, v in ends):
            continue
        COVERED["infomap"] += 1
        G = igraph.Graph(n=n, edges=ends)
        igraph.set_random_number_generator(random.Random(n))
        theirs = G.community_infomap(edge_weights=w, trials=10).codelength
        igraph.set_random_number_generator(random)
        if ours > theirs + INFOMAP_SLACK * max(1.0, theirs):
            problems.append(f"{key}: code length {ours}, igraph's {theirs}, longer by more than {INFOMAP_SLACK} relative")
        if ours > theirs + 1e-9:
            COVERED["infomap longer than igraph's"] += 1
        elif ours < theirs - 1e-9:
            COVERED["infomap shorter than igraph's"] += 1
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
