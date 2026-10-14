"""Exact Python ports of Swift's _leiden and _fluidCommunities, draw for draw, with SplitMix64 and
the standard library's next(upperBound:) (Lemire's method), for the pinned-draw tests. `M` plants
the bugs of scripts/mutants/CommunityDetection.py (ld*, fl*), to find inputs that tell them apart.

Run: python3 draws.py   (writes Tests/CommunityDetectionTests/LeidenDrawTests.swift)"""
import math

M64 = (1 << 64) - 1


class SplitMix:
    def __init__(self, state):
        self.state = state & M64

    def next(self):
        self.state = (self.state + 0x9E3779B97F4A7C15) & M64
        z = self.state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)

    def upper(self, bound):
        r = self.next()
        m = r * bound
        low, high = m & M64, m >> 64
        if low < bound:
            t = ((1 << 64) - bound) % bound
            while low < t:
                r = self.next()
                m = r * bound
                low, high = m & M64, m >> 64
        return high

    def unit(self):
        return (self.next() >> 11) * 2.0 ** -53


def shuffled(k, g):
    order = list(range(k))
    i = k - 1
    while i > 0:
        j = g.upper(i + 1)
        order[i], order[j] = order[j], order[i]
        i -= 1
    return order


def level(k, directed, frm, to, weight):
    start = [0] * (k + 1)
    keyx = [(frm[i] if directed else min(frm[i], to[i])) for i in range(len(frm))]
    for x in keyx:
        start[x + 1] += 1
    for v in range(k):
        start[v + 1] += start[v]
    fill = start[:]
    order = [0] * len(frm)
    for i, x in enumerate(keyx):
        order[fill[x]] = i
        fill[x] += 1
    seen, slot = [-1] * k, [0] * k
    pf, pt, pw = [], [], []
    for x in range(k):
        for pos in range(start[x], start[x + 1]):
            i = order[pos]
            y = to[i] if directed else max(frm[i], to[i])
            if seen[y] == x:
                pw[slot[y]] += weight(i)
            else:
                seen[y] = x
                slot[y] = len(pw)
                pf.append(x)
                pt.append(y)
                pw.append(weight(i))
    return dict(k=k, directed=directed, pf=pf, pt=pt, pw=pw)


def rows_of(lv):
    k, directed = lv["k"], lv["directed"]
    out, into = [0.0] * k, [0.0] * k
    counts = [0] * (k + 1)
    for a, b, x in zip(lv["pf"], lv["pt"], lv["pw"]):
        out[a] += x
        into[b] += x
        if not directed:
            out[b] += x
            into[a] += x
        if a != b:
            counts[a + 1] += 1
            counts[b + 1] += 1
    for v in range(k):
        counts[v + 1] += counts[v]
    fill = counts[:]
    rn, rw = [0] * counts[k], [0.0] * counts[k]
    for a, b, x in zip(lv["pf"], lv["pt"], lv["pw"]):
        if a == b:
            continue
        rn[fill[a]] = b
        rw[fill[a]] = x
        fill[a] += 1
        rn[fill[b]] = a
        rw[fill[b]] = x
        fill[b] += 1
    offsets, nbrs, ws = [0] * (k + 1), [], []
    where = [-1] * k
    for v in range(k):
        st = len(nbrs)
        for s in range(counts[v], counts[v + 1]):
            w = rn[s]
            at = where[w]
            if st <= at < len(nbrs) and nbrs[at] == w:
                ws[at] += rw[s]
            else:
                where[w] = len(nbrs)
                nbrs.append(w)
                ws.append(rw[s])
        offsets[v + 1] = len(nbrs)
    return dict(out=out, into=into, offsets=offsets, nbrs=nbrs, ws=ws)


def ulp(x):
    return math.ulp(x)


def move(rows, com, a, b, gamma, g, M):
    k = len(com)
    if k <= 1:
        return False
    moved = False
    order = shuffled(k, g)
    A, B, size = [0.0] * k, [0.0] * k, [0] * k
    for v in range(k):
        A[com[v]] += a[v]
        B[com[v]] += b[v]
        size[com[v]] += 1
    empty = [c for c in range(k - 1, -1, -1) if size[c] == 0]
    queue = list(order)
    queued = [True] * k
    head = 0
    off, nb, ws = rows["offsets"], rows["nbrs"], rows["ws"]
    while head < len(queue):
        v = queue[head]
        head += 1
        queued[v] = False
        cur = com[v]
        to, touched = {}, []
        for s in range(off[v], off[v + 1]):
            c = com[nb[s]]
            if c not in to:
                to[c] = 0.0
                touched.append(c)
            to[c] += ws[s]
        av, bv = a[v], b[v]
        ownA, ownB = A[cur] - av, B[cur] - bv
        bestLink = to.get(cur, 0.0)
        bestPen = gamma * (av * ownB + bv * ownA)
        best = bestLink - bestPen
        chosen = cur
        if size[cur] > 1 and not M.get("noempty"):
            tol = 4 * ulp(max(abs(bestLink), abs(bestPen)))
            if -best > tol:
                best, bestLink, bestPen, chosen = 0.0, 0.0, 0.0, -1
        for c in touched:
            if c == cur:
                continue
            link, pen = to[c], gamma * (av * B[c] + bv * A[c])
            gain = link - pen
            tol = 4 * ulp(max(abs(link), abs(pen), abs(bestLink), abs(bestPen)))
            if gain - best > tol:
                best, bestLink, bestPen, chosen = gain, link, pen, c
        if chosen == cur:
            continue
        if chosen < 0:
            chosen = empty.pop()
        A[cur], B[cur] = ownA, ownB
        size[cur] -= 1
        if size[cur] == 0:
            empty.append(cur)
        A[chosen] += av
        B[chosen] += bv
        size[chosen] += 1
        com[v] = chosen
        moved = True
        if M.get("norequeue"):
            continue
        for s in range(off[v], off[v + 1]):
            w = nb[s]
            if not queued[w] and com[w] != chosen:
                queued[w] = True
                queue.append(w)
    return moved


def refine(rows, com, a, b, gamma, theta, g, M):
    k = len(com)
    ref = list(range(k))
    if k <= 1:
        return ref
    order = shuffled(k, g)
    off, nb, ws = rows["offsets"], rows["nbrs"], rows["ws"]
    sA, sB = [0.0] * k, [0.0] * k
    ext = [0.0] * k
    for v in range(k):
        c = com[v]
        sA[c] += a[v]
        sB[c] += b[v]
        inside = 0.0
        for s in range(off[v], off[v + 1]):
            if com[nb[s]] == c:
                inside += ws[s]
        ext[v] = inside
    rA, rB, rE, rS = a[:], b[:], ext[:], [1] * k
    for v in order:
        if not M.get("nosingleton") and (ref[v] != v or rS[v] != 1):
            continue
        c = com[v]
        av, bv = a[v], b[v]
        tA, tB = sA[c], sB[c]
        if not M.get("nowell") and not (ext[v] >= gamma * (av * (tB - bv) + bv * (tA - av))):
            continue
        to, touched = {}, []
        for s in range(off[v], off[v + 1]):
            w = nb[s]
            if com[w] != c and not M.get("nosame"):
                continue
            r = ref[w]
            if r not in to:
                to[r] = 0.0
                touched.append(r)
            to[r] += ws[s]
        cands, most = [], 0.0
        for r in touched:
            ra, rb = rA[r], rB[r]
            if not M.get("norefwell") and not (rE[r] >= gamma * (ra * (tB - rb) + rb * (tA - ra))):
                continue
            gain = to[r] - gamma * (av * rb + bv * ra)
            if gain < 0 and not M.get("negative"):
                continue
            cands.append([r, gain])
            if gain > most:
                most = gain
        if not cands:
            continue
        stay = math.exp((0 - most) / theta)
        total = stay
        for cd in cands:
            cd[1] = math.exp((cd[1] - most) / theta)
            total += cd[1]
        x = g.unit() * total
        if x < stay and not M.get("nostay"):
            continue
        x -= stay
        pick = len(cands) - 1
        for i in range(len(cands) - 1):
            if x < cands[i][1]:
                pick = i
                break
            x -= cands[i][1]
        r = cands[pick][0]
        ref[v] = r
        rA[r] += av
        rB[r] += bv
        rS[r] += 1
        rS[v] = 0
        if not M.get("noexternal"):
            rE[r] += ext[v] - 2 * to[r]
    return ref


def leiden(n, ends, directed, weights, potts, resolution, theta, seed, iterations=None, M=None):
    M = M or {}
    g = SplitMix(seed)
    if n <= 1:
        return list(range(n))
    m = sum(weights) if weights is not None else float(len(ends))
    if not potts and m == 0:
        return list(range(n))
    gamma = (resolution / m if directed else resolution / (4 * m)) if not potts else (resolution if directed else resolution / 2)
    frm = [u for u, v in ends]
    to = [v for u, v in ends]
    base = level(n, directed, frm, to, lambda i: weights[i] if weights is not None else 1.0)
    brows = rows_of(base)
    a0 = brows["out"][:] if not potts else [1.0] * n
    b0 = brows["into"][:] if not potts else a0[:]
    membership = list(range(n))
    it = 0
    while iterations is None or it < iterations:
        it += 1
        lv, rows, a, b = base, brows, a0, b0
        node = list(range(n))
        com = membership[:]
        changed = False
        while True:
            if move(rows, com, a, b, gamma, g, M):
                changed = True
            k = lv["k"]
            rank = [-1] * k
            cnt = 0
            for c in com:
                if rank[c] < 0:
                    rank[c] = cnt
                    cnt += 1
            if cnt == k:
                break
            ref = refine(rows, com, a, b, gamma, theta, g, M)
            # Each level vertex's next-level vertex: its refined community's, or its community's
            # when the refinement merged nothing.
            group = [-1] * k
            count = 0
            for v in range(k):
                if ref[v] == v:
                    group[v] = count
                    count += 1
            if count == k:
                if M.get("nofallback"):
                    break
                group = [rank[c] for c in com]
                count = cnt
            else:
                group = [group[ref[v]] for v in range(k)]
            na, nb2, nc = [0.0] * count, [0.0] * count, [0] * count
            for v in range(k):
                r = group[v]
                na[r] += a[v]
                nb2[r] += b[v]
                nc[r] = rank[com[v]]
            pairs = lv
            lv = level(count, directed, [group[x] for x in pairs["pf"]], [group[x] for x in pairs["pt"]], lambda i: pairs["pw"][i])
            rows = rows_of(lv)
            a, b, com = na, nb2, nc
            node = [group[x] for x in node]
        if not changed and not M.get("onepass"):
            break
        membership = [com[node[v]] for v in range(n)]
        if M.get("onepass"):
            break
    return membership if M.get("nosplit") else connected_parts(brows, membership)


def connected_parts(rows, labels):
    """_connectedParts: each community split into the parts the rows connect, a label per vertex
    (the least vertex of its part)."""
    n = len(labels)
    part = [-1] * n
    for s in range(n):
        if part[s] >= 0:
            continue
        part[s] = s
        stack = [s]
        while stack:
            v = stack.pop()
            for slot in range(rows["offsets"][v], rows["offsets"][v + 1]):
                w = rows["nbrs"][slot]
                if part[w] < 0 and labels[w] == labels[s]:
                    part[w] = s
                    stack.append(w)
    return part


def canonical(labels):
    seen = {}
    groups = []
    for v, l in enumerate(labels):
        if l not in seen:
            seen[l] = len(groups)
            groups.append([])
        groups[seen[l]].append(v)
    return groups


def merged_rows(n, ends):
    """_MergedRows: each row in incidentEdges (position) order, repeats merged, loops out."""
    raw = [[] for _ in range(n)]
    for u, v in ends:
        if u == v:
            continue
        raw[u].append(v)
        raw[v].append(u)
    # ReferencePseudograph rows: incident edges in position order; merge repeats.
    rows = []
    for v in range(n):
        seen = []
        for w in raw[v]:
            if w not in seen:
                seen.append(w)
        rows.append(seen)
    return rows


def fluid(n, ends, k, seed, iterations=100, M=None):
    M = M or {}
    g = SplitMix(seed)
    rows = merged_rows(n, ends)
    community = [-1] * n
    size, density = [0] * k, [0.0] * k
    seeds = shuffled(n, g)[:k]
    for c, v in enumerate(seeds):
        community[v] = c
        size[c] = 1
        density[c] = 1.0
    changed, sweep = True, 0
    while changed and sweep < iterations:
        changed = False
        sweep += 1
        for v in shuffled(n, g):
            total, touched = {}, []
            own = community[v]
            if own >= 0:
                total[own] = density[own]
                touched.append(own)
            for w in rows[v]:
                c = community[w]
                if c < 0:
                    continue
                if c not in total:
                    total[c] = 0.0
                    touched.append(c)
                total[c] += density[c]
            if not touched:
                continue
            most = total[touched[0]]
            for c in touched:
                if total[c] > most:
                    most = total[c]
            best, keeps = [], False
            for c in touched:
                tie = (most == total[c]) if M.get("exact") else (most - total[c] < 1e-4)
                if tie:
                    best.append(c)
                    if c == own:
                        keeps = True
            if keeps and not M.get("nokeep"):
                continue
            changed = True
            chosen = best[g.upper(len(best))]
            if own >= 0:
                size[own] -= 1
                density[own] = 1 / size[own] if size[own] > 0 else 0.0
            community[v] = chosen
            size[chosen] += 1
            if not M.get("nodensity"):
                density[chosen] = 1 / size[chosen]
    return [v if community[v] < 0 else seeds[community[v]] for v in range(n)]


# --------------------------------------------------------------------------------------------
# The pinned-draw tests: `python3 draws.py` writes Tests/CommunityDetectionTests/LeidenDrawTests.swift.
# --------------------------------------------------------------------------------------------

import random
from pathlib import Path

# Cases where a planted bug in scripts/mutants/CommunityDetection.py changes the answer (found by
# running this model with the bug), then seeded random cases. Each: (name, kind, arguments).
PINNED = [
    ("an empty community is a move's choice", "leiden", dict(n=6, ends=[(2, 5), (2, 2), (5, 5), (1, 1), (0, 4), (4, 1), (2, 3)], directed=False, w=None, potts=False, res=1.0, theta=0.01, seed=2349028542, it=2)),
    ("a move queues the mover's neighbors", "leiden", dict(n=6, ends=[(1, 3), (5, 1), (0, 1), (2, 2), (5, 1), (5, 3), (5, 3), (2, 3), (5, 5), (5, 1), (3, 3)], directed=False, w=None, potts=True, res=0.5, theta=0.5, seed=643735021, it=1)),
    ("the refinement merges only well-connected vertices into well-connected communities, and a draw can keep a vertex alone", "leiden", dict(n=9, ends=[(6, 1), (2, 4), (4, 0), (8, 0), (2, 6), (8, 1), (7, 0), (6, 6), (4, 5), (6, 6), (7, 0), (1, 7), (0, 0), (0, 1), (2, 8)], directed=False, w=None, potts=True, res=0.3, theta=5.0, seed=2812612325, it=1)),
    ("a refinement that merges nothing aggregates by the communities instead", "leiden", dict(n=7, ends=[(6, 0), (0, 4), (0, 2), (0, 1), (2, 1), (0, 3), (2, 0)], directed=False, w=None, potts=False, res=1.0, theta=5.0, seed=1204001940, it=2)),
    ("the refinement never merges at a negative gain", "leiden", dict(n=8, ends=[(5, 3), (5, 7), (3, 2), (0, 5), (4, 3), (4, 3), (4, 7), (4, 0), (2, 6), (1, 4), (7, 3), (4, 3), (5, 4), (4, 1), (0, 1)], directed=False, w=None, potts=False, res=1.0, theta=5.0, seed=2375950889, it=2)),
    ("a refined community's weight to the rest of its community follows its merges", "leiden", dict(n=7, ends=[(0, 1), (4, 0), (0, 0), (0, 0), (0, 2), (5, 3), (3, 5), (1, 3), (2, 2), (6, 4), (5, 0)], directed=False, w=[3.0, 2.0, 0.0, 2.0, 2.0, 2.0, 3.0, 2.0, 1.0, 1.0, 3.0], potts=False, res=1.0, theta=5.0, seed=1394153924, it=2)),
    ("a community whose parts tie at gain 0 is split into its connected parts", "leiden", dict(n=6, ends=[(2, 0), (0, 1), (3, 0), (4, 0)], directed=True, w=None, potts=False, res=1.0, theta=0.01, seed=105, it=None)),
    ("iterations continue while one moves a vertex", "leiden", dict(n=9, ends=[(6, 2), (5, 4), (1, 6), (5, 1), (4, 1), (4, 5), (6, 6), (1, 1), (4, 1), (2, 0), (1, 8), (6, 1), (7, 6), (1, 3), (6, 0), (8, 4), (1, 8), (5, 5), (1, 7), (6, 1), (2, 3), (1, 8), (1, 1), (8, 6), (6, 1)], directed=False, w=None, potts=True, res=1.0, theta=0.01, seed=3525521651, it=None)),
    ("a vertex keeps its own community on a tie", "fluid", dict(n=7, ends=[(5, 2), (6, 5), (6, 5), (5, 4), (0, 6), (3, 6), (1, 5), (0, 1), (0, 2), (3, 6), (1, 3), (4, 0), (4, 1), (0, 5)], k=7, seed=3423720279)),
    ("density sums within 10⁻⁴ tie", "fluid", dict(n=9, ends=[(4, 4), (4, 4), (6, 1), (7, 5), (3, 7), (8, 6), (7, 0), (5, 0), (6, 5), (2, 7), (2, 1), (7, 2), (7, 3), (3, 4), (4, 2), (7, 6), (1, 3), (4, 4), (0, 3), (2, 7), (8, 1), (8, 7), (8, 5), (7, 1), (8, 3), (7, 4), (2, 0)], k=2, seed=2209942359)),
    ("a community's density follows its size", "fluid", dict(n=4, ends=[(3, 1), (1, 0), (0, 1), (1, 1), (1, 2), (2, 1), (1, 1), (1, 3), (2, 0), (2, 3), (1, 1), (2, 0)], k=3, seed=283564262)),
]


def random_cases(count, seed):
    rng = random.Random(seed)
    out = []
    while len(out) < count:
        n = rng.randint(3, 10)
        ends = [(rng.randrange(n), rng.randrange(n)) for _ in range(rng.randint(n, 3 * n))]
        args = dict(n=n, ends=ends, directed=rng.random() < 0.35,
                    w=[float(rng.randint(0, 3)) for _ in ends] if rng.random() < 0.5 else None,
                    potts=rng.random() < 0.5, res=rng.choice([0.0, 0.2, 0.5, 1.0, 2.0]),
                    theta=rng.choice([0.01, 0.5, 5.0]), seed=rng.randrange(1 << 32), it=rng.choice([None, None, 1, 2]))
        out.append((f"seeded case {len(out) + 1}", "leiden", args))
    return out


def lit(x):
    return repr(float(x)) if isinstance(x, float) else str(x)


def test_lines(i, name, kind, a):
    n, ends = a["n"], a["ends"]
    pairs = ", ".join(f"({u}, {v})" for u, v in ends)
    out = [f'    @Test("{name}")', f"    func case{i}() {{"]
    out.append(f"        let pairs: [(Int, Int)] = [{pairs}]")
    if kind == "fluid":
        expected = canonical(fluid(n, ends, a["k"], a["seed"]))
        out.append(f"        let graph = ReferencePseudograph(vertices: 0 ..< {n}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
        out.append(f"        var generator = SplitMix64(state: {a['seed']})")
        out.append(f"        let result = graph.asynchronousFluidCommunities(count: {a['k']}, using: &generator)")
    else:
        expected = canonical(leiden(n, ends, a["directed"], a["w"], a["potts"], a["res"], a["theta"], a["seed"], a["it"]))
        if a["directed"]:
            out.append(f"        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< {n}, edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }})")
        else:
            out.append(f"        let graph = ReferencePseudograph(vertices: 0 ..< {n}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
        args = []
        if a["w"] is not None:
            out.append(f"        let w: [Double] = [{', '.join(lit(x) for x in a['w'])}]")
            args.append("weight: { w[$0] }")
        if a["potts"]:
            args.append("quality: .constantPottsModel")
        args.append(f"resolution: {lit(a['res'])}")
        args.append(f"randomness: {lit(a['theta'])}")
        if a["it"] is not None:
            args.append(f"iterations: {a['it']}")
        out.append(f"        var generator = SplitMix64(state: {a['seed']})")
        out.append(f"        let result = graph.leidenCommunities({', '.join(args)}, using: &generator)")
    groups = ", ".join("[" + ", ".join(map(str, c)) + "]" for c in expected)
    out.append(f"        #expect(result.map {{ Array($0) }} == [{groups}])")
    out.append("    }")
    return out


def main():
    cases = PINNED + random_cases(24, 1)
    lines = ["""// Leiden and asynchronous fluid communities draw for draw: each case runs with a SplitMix64 stream
// and compares the partition with draws.py's exact model of the implementation (the same orders,
// candidate lists, tolerances and draws: Fisher–Yates shuffles by `next(upperBound:)`, a refinement
// draw as the top 53 bits of `next()`), so every rule of the move phase, the refinement, the stop
// test and the fluid sweeps is pinned. The first cases are inputs on which a planted bug changes the
// answer; the rest are seeded random multigraphs with loops, directed and undirected, weighted and
// not, both quality functions. Generated by Tests/Catalogs/CommunityDetection/draws.py; edit it and
// regenerate rather than editing this file.

import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

/// SplitMix64 (Steele, Lea and Flood 2014), as draws.py runs it.
private struct SplitMix64: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@Suite("Leiden and fluid communities draw for draw")
struct LeidenDrawTests {"""]
    for i, (name, kind, a) in enumerate(cases):
        if i:
            lines.append("")
        lines += test_lines(i + 1, name, kind, a)
    lines.append("}")
    out = Path(__file__).resolve().parent.parent.parent / "CommunityDetectionTests" / "LeidenDrawTests.swift"
    out.write_text("\n".join(lines) + "\n")
    print(len(cases), "cases")


if __name__ == "__main__":
    main()
