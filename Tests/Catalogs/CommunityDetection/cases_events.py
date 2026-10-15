# The Louvain events of CD-900 and CD-901, from a plain model of api.md's Louvain in index order:
# every vertex is evaluated in every sweep (the library skips vertices whose inputs did not change,
# which moves nothing differently), a move goes to the greatest gain, staying on a tie and
# otherwise taking the greatest label, and a move's gain is (best − stay) / m², the rise in
# modularity. Prints cases_events.out. Run: python3 Tests/Catalogs/CommunityDetection/cases_events.py
import os


def modularity(n, ends, w, labels, gamma, directed):
    m = sum(w)
    k = max(labels) + 1
    inside, out, inn = [0.0] * k, [0.0] * k, [0.0] * k
    for (a, b), x in zip(ends, w):
        if labels[a] == labels[b]:
            inside[labels[a]] += x
        out[labels[a]] += x
        inn[labels[b]] += x
        if not directed:
            out[labels[b]] += x
            inn[labels[a]] += x
    if directed:
        return sum(inside[c] / m - gamma * out[c] * inn[c] / (m * m) for c in range(k))
    return sum(inside[c] / m - gamma * (out[c] / (2 * m)) ** 2 for c in range(k))


def one_level(k, pairs, directed, m, resolution, out_events):
    out, inn = [0.0] * k, [0.0] * k
    nbrs = [dict() for _ in range(k)]
    for (a, b), x in pairs.items():
        out[a] += x
        inn[b] += x
        if not directed:
            out[b] += x
            inn[a] += x
        if a != b:
            nbrs[a][b] = nbrs[a].get(b, 0.0) + x
            nbrs[b][a] = nbrs[b].get(a, 0.0) + x
    com = list(range(k))
    gamma = resolution if directed else resolution / 2
    S_in, S_out = inn[:], out[:]
    moved, moves = False, 1
    while moves > 0:
        moves = 0
        for u in range(k):
            uc = com[u]
            kin = {}
            for v, x in nbrs[u].items():
                kin[com[v]] = kin.get(com[v], 0.0) + x
            ind, outd = inn[u], out[u]
            own_in = S_in[uc] - ind if directed else 0
            own_out = S_out[uc] - outd
            t = outd * own_in + ind * own_out if directed else own_out * outd
            best, bc = kin.get(uc, 0.0) * m - gamma * t, uc
            stay = best
            for c, x in kin.items():
                if c == uc:
                    continue
                t = outd * S_in[c] + ind * S_out[c] if directed else S_out[c] * outd
                gain = x * m - gamma * t
                if gain > best or (gain == best and bc != uc and c > bc):
                    best, bc = gain, c
            if bc == uc:
                continue
            if directed:
                S_in[uc] = own_in
                S_in[bc] += ind
            S_out[uc] = own_out
            S_out[bc] += outd
            com[u] = bc
            moves += 1
            moved = True
            out_events.append(("move", u, uc, bc, (best - stay) / (m * m)))
    return com, moved


def events(n, ends, w, directed, resolution=1.0, threshold=1e-7):
    m = sum(w)
    pairs = {}
    for (a, b), x in zip(ends, w):
        key = (a, b) if directed else (min(a, b), max(a, b))
        pairs[key] = pairs.get(key, 0.0) + x
    k, node = n, list(range(n))
    mod = modularity(n, ends, w, list(range(n)), resolution, directed)
    out = []
    com, moved = one_level(k, pairs, directed, m, resolution, out)
    while True:
        rank = {c: i for i, c in enumerate(sorted(set(com)))}
        labels = [rank[com[node[v]]] for v in range(n)]
        new = modularity(n, ends, w, labels, resolution, directed)
        out.append(("levelFinished", labels, new))
        if new - mod <= threshold:
            return out
        mod = new
        nxt = {}
        for (a, b), x in pairs.items():
            key = (rank[com[a]], rank[com[b]])
            if not directed:
                key = (min(key), max(key))
            nxt[key] = nxt.get(key, 0.0) + x
        out.append(("aggregate", len(rank)))
        pairs, k, node = nxt, len(rank), labels
        com, moved = one_level(k, pairs, directed, m, resolution, out)
        if not moved:
            return out


# CD-900: two triangles joined by 2–3, then a third triangle hanging off 5 by 5–6.
CD900 = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (4, 5), (3, 5), (5, 6), (6, 7), (7, 8), (6, 8)]
# CD-901: a ring of twelve triangles, each joined to the next by one edge: the first level finds
# the triangles, the second pairs them.
CD901 = []
for c in range(12):
    b = 3 * c
    CD901 += [(b, b + 1), (b + 1, b + 2), (b, b + 2), (b + 2, (b + 3) % 36)]
lines = []
for name, n, ends in [("CD-900", 9, CD900), ("CD-901", 36, CD901)]:
    ev = events(n, ends, [1.0] * len(ends), False)
    lines.append(f"--- {name}: {len(ev)} events")
    for e in ev:
        lines.append(" ".join(f"{x:.17g}" if isinstance(x, float) else str(x) for x in e))
text = "\n".join(lines) + "\n"
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cases_events.out"), "w") as f:
    f.write(text)
print(text, end="")
