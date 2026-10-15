# The Bron–Kerbosch events of CQ-1100, from a plain recursive model of api.md's enumeration, each
# call as the vertex it adds to R and the contents of R, P and X: outer calls in the degeneracy
# ordering (given here as the library reports it, which the test pins),
# R = {v}, P = v's later neighbors, X = its earlier ones; Tomita's pivot maximizes |P ∩ N(u)| over
# P ∪ X, ties to the least vertex; branches over P \ N(pivot) in ascending order. Prints
# cases_events.out. Run: python3 Tests/Catalogs/Cliques/cases_events.py
import os


def events(n, edges, order):
    nbrs = [set() for _ in range(n)]
    for u, v in edges:
        if u != v:
            nbrs[u].add(v)
            nbrs[v].add(u)
    rank = {v: i for i, v in enumerate(order)}
    out = []

    def call(r, p, x):
        out.append(("call", "+%d" % r[-1], sorted(r), sorted(p), sorted(x)))
        if not p:
            if not x:
                out.append(("maximalClique", sorted(r)))
            out.append(("backtrack",))
            return
        pivot = min(sorted(p) + sorted(x), key=lambda u: (-len(p & nbrs[u]), u))
        out.append(("pivot", pivot))
        for w in sorted(p - nbrs[pivot]):
            call(r + [w], p & nbrs[w], x & nbrs[w])
            p = p - {w}
            x = x | {w}
        out.append(("backtrack",))

    for v in order:
        later = {u for u in nbrs[v] if rank[u] > rank[v]}
        earlier = {u for u in nbrs[v] if rank[u] < rank[v]}
        call([v], later, earlier)
    return out


# CQ-1100: two triangles 0–1–2 and 1–2–3 sharing 1–2, a path 3–4–5, a loop at 5, isolated 6.
CL900 = [(0, 1), (1, 2), (0, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 5)]
ORDER = [6, 5, 4, 0, 3, 1, 2]
ev = events(7, CL900, ORDER)
lines = [f"--- CQ-1100: {len(ev)} events, order {ORDER}"] + [" ".join(str(x) for x in e) for e in ev]
text = "\n".join(lines) + "\n"
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cases_events.out"), "w") as f:
    f.write(text)
print(text, end="")
