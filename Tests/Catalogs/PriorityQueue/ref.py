"""Reference models for Grafluent's IndexedPriorityQueue research.

IPQ    -- the recommended design: a d-ary (default 4) min-heap of (priority, index) pairs plus a
          position array (-1 = absent). Ties are NOT broken by index: sifts compare priorities
          with strict `<` only, exactly as the Swift prototype's `IndexedHeap<_, _, 4, 0>`.
          `bugs` switches on planted bugs (see plant.py).
Naive  -- an independent oracle: a dict index -> priority; popMin scans for the minimum and
          reports the set of indices tied at it.

Run `python3 ref.py` to print every derived value used in the catalog (cases.out).
"""
import random


class Trap(Exception):
    pass


class IPQ:
    def __init__(self, bound, d=4, bugs=frozenset()):
        if bound < 0:
            raise Trap("negative bound")
        self.d = d
        self.bugs = bugs
        self.bound = bound
        self.heap = []          # list of [priority, index]
        self.pos = [-1] * bound

    # -- copy (value semantics) ---------------------------------------------------------------
    def copy(self):
        c = IPQ.__new__(IPQ)
        c.d, c.bugs, c.bound = self.d, self.bugs, self.bound
        if "shared-storage" in self.bugs:      # reference semantics: copies alias
            c.heap, c.pos = self.heap, self.pos
        else:
            c.heap = [list(e) for e in self.heap]
            c.pos = list(self.pos)
        return c

    # -- queries ------------------------------------------------------------------------------
    def _check(self, i):
        if not (0 <= i < self.bound):
            raise Trap(f"index {i} out of range 0..<{self.bound}")

    @property
    def count(self):
        return len(self.heap)

    @property
    def is_empty(self):
        return not self.heap

    def contains(self, i):
        self._check(i)
        return self.pos[i] >= 0

    def priority_of(self, i):
        self._check(i)
        h = self.pos[i]
        return None if h < 0 else self.heap[h][0]

    @property
    def min(self):
        return None if not self.heap else (self.heap[0][1], self.heap[0][0])

    def unordered(self):
        return [(i, p) for p, i in self.heap]

    # -- sifting --------------------------------------------------------------------------------
    def _less(self, a, b):
        return a[0] < b[0]

    def _parent(self, h):
        if "parent-off-by-one" in self.bugs:
            return h // self.d
        return (h - 1) // self.d

    def _place(self, h, e):
        self.heap[h] = e
        self.pos[e[1]] = h

    def _sift_up(self, h, e):
        while h > 0:
            p = self._parent(h)
            if p == h:
                break
            pe = self.heap[p]
            if "siftup-non-strict" in self.bugs:
                if pe[0] < e[0]:
                    break
            elif not self._less(e, pe):
                break
            self.heap[h] = pe
            if "siftup-no-pos" not in self.bugs:
                self.pos[pe[1]] = h
            h = p
        self._place(h, e)

    def _sift_down(self, h, e):
        n = len(self.heap)
        while True:
            first = h * self.d + 1
            if first >= n:
                break
            width = self.d - 1 if "short-child-scan" in self.bugs else self.d
            end = min(first + width, n)
            best = first
            for c in range(first + 1, end):
                if self._less(self.heap[c], self.heap[best]):
                    best = c
            be = self.heap[best]
            if "siftdown-non-strict" in self.bugs:
                if e[0] < be[0]:
                    break
            elif not self._less(be, e):
                break
            self.heap[h] = be
            self.pos[be[1]] = h
            h = best
        self._place(h, e)

    @staticmethod
    def _check_priority(p):
        if p != p:
            raise Trap("NaN priority")

    # -- mutations ------------------------------------------------------------------------------
    def insert(self, i, p):
        self._check(i)
        self._check_priority(p)
        if self.pos[i] >= 0 and "insert-no-dup-check" not in self.bugs:
            raise Trap(f"index {i} is already in the queue")
        self.heap.append(None)
        self._sift_up(len(self.heap) - 1, [p, i])

    def decrease_priority(self, i, p):
        self._check(i)
        self._check_priority(p)
        h = self.pos[i]
        if h < 0:
            raise Trap(f"index {i} is not in the queue")
        if p > self.heap[h][0] and "decrease-no-check" not in self.bugs:
            raise Trap("decreasePriority to a larger priority")
        e = [self.heap[h][0] if "decrease-keeps-old" in self.bugs else p, i]
        if "decrease-sifts-down" in self.bugs:
            self._sift_down(h, e)
        else:
            self._sift_up(h, e)

    def update_priority(self, i, p):
        self._check(i)
        self._check_priority(p)
        h = self.pos[i]
        if h < 0:
            raise Trap(f"index {i} is not in the queue")
        old = self.heap[h][0]
        e = [p, i]
        if "update-only-up" in self.bugs or p < old:
            self._sift_up(h, e)
        else:
            self._sift_down(h, e)
        return old

    def remove(self, i):
        self._check(i)
        h = self.pos[i]
        if h < 0:
            return None
        old = self.heap[h][0]
        self.pos[i] = -1
        last = self.heap.pop()
        if h < len(self.heap):
            if "remove-only-down" in self.bugs:
                self._sift_down(h, last)
            elif self._less(last, [old, i]):
                self._sift_up(h, last)
            else:
                self._sift_down(h, last)
        return old

    def pop_min(self):
        if not self.heap:
            return None
        last = self.heap.pop()
        if not self.heap:
            if "pop-single-keeps-pos" not in self.bugs:
                self.pos[last[1]] = -1
            return (last[1], last[0])
        top = self.heap[0]
        if "pop-keeps-pos" not in self.bugs:
            self.pos[top[1]] = -1
        self._sift_down(0, last)
        return (top[1], top[0])

    def remove_min(self):
        if not self.heap:
            raise Trap("removeMin on an empty queue")
        return self.pop_min()

    def remove_all(self):
        if "removeall-keeps-pos" not in self.bugs:
            for _, i in self.heap:
                self.pos[i] = -1
        self.heap = []

    # -- internal check (used only by the reference, never by catalog cases) ------------------
    def valid(self):
        for h in range(1, len(self.heap)):
            if self.heap[h][0] < self.heap[(h - 1) // self.d][0]:
                return False
        for h, (_, i) in enumerate(self.heap):
            if self.pos[i] != h:
                return False
        return sum(1 for x in self.pos if x >= 0) == len(self.heap)


class Naive:
    """Oracle: dict index -> priority."""

    def __init__(self, bound):
        self.bound = bound
        self.pr = {}

    def insert(self, i, p):
        assert i not in self.pr
        self.pr[i] = p

    def set(self, i, p):
        assert i in self.pr
        old = self.pr[i]
        self.pr[i] = p
        return old

    def remove(self, i):
        return self.pr.pop(i, None)

    def min_set(self):
        if not self.pr:
            return None, set()
        m = min(self.pr.values())
        return m, {i for i, p in self.pr.items() if p == m}


# ---------------------------------------------------------------------------------------------
# Shared data from the OSS tests
# ---------------------------------------------------------------------------------------------

LEMON_SEQ = [2, 28, 19, 27, 33, 25, 13, 41, 10, 26, 1, 9, 4, 34]   # lemon test/heap_test.cc:87
LEMON_INC = [20, 28, 34, 16, 0, 46, 44, 0, 42, 32, 14, 8, 6, 37]   # lemon test/heap_test.cc:88

# lemon test/heap_test.cc:49-84: arcs (source, target, length); source node 3
LEMON_ARCS = [(0, 5, 94), (3, 9, 11), (8, 7, 83), (1, 2, 94), (5, 7, 35), (7, 4, 84), (9, 5, 38),
              (0, 4, 96), (6, 7, 6), (3, 1, 27), (5, 2, 77), (5, 6, 69), (6, 5, 41), (4, 6, 70),
              (3, 2, 45), (7, 9, 93), (5, 9, 50), (9, 0, 94), (9, 6, 67), (0, 9, 86)]

# igraph tests/unit/2wheap.c:105-151, the "hand-made example" (a Dijkstra trace on a max-heap of
# negated distances). Translated to a min-queue: PUSH -> insert, MOD -> decrease, MAX -> popMin.
IGRAPH_TRACE = [("push", 4, 0.0), ("pop",), ("push", 11, 0.63), ("push", 15, 0.05), ("pop",),
                ("push", 12, 0.4), ("push", 13, 0.4), ("push", 16, 0.12), ("pop",),
                ("push", 0, 1.1), ("push", 14, 1.1), ("pop",), ("mod", 11, 0.44), ("pop",),
                ("pop",), ("push", 20, 1.1), ("pop",), ("push", 7, 1.3), ("push", 9, 1.7),
                ("pop",), ("push", 19, 1.6), ("pop",), ("push", 17, 2.1), ("push", 18, 1.3),
                ("pop",), ("push", 1, 2.3), ("push", 5, 2.2), ("push", 10, 2.3), ("pop",),
                ("mod", 17, 1.5), ("pop",), ("push", 6, 1.8), ("pop",), ("push", 3, 1.3),
                ("mod", 6, 1.3), ("pop",), ("push", 8, 1.6), ("pop",)]


def dijkstra(n, arcs, s, make_queue=lambda n: IPQ(n)):
    adj = [[] for _ in range(n)]
    for u, v, w in arcs:
        adj[u].append((v, w))
    inf = float("inf")
    dist = [inf] * n
    dist[s] = 0
    q = make_queue(n)
    q.insert(s, 0)
    order = []
    while True:
        e = q.pop_min()
        if e is None:
            break
        u, du = e
        order.append((u, du))
        for v, w in adj[u]:
            nd = du + w
            if nd < dist[v]:
                if q.contains(v):
                    q.decrease_priority(v, nd)
                else:
                    q.insert(v, nd)
                dist[v] = nd
    return dist, order


def bellman_ford(n, arcs, s):
    inf = float("inf")
    d = [inf] * n
    d[s] = 0
    for _ in range(n):
        for u, v, w in arcs:
            if d[u] + w < d[v]:
                d[v] = d[u] + w
    return d


def pop_groups(q):
    """Pops everything; returns [(priority, sorted indices tied at it)] in pop order."""
    out = []
    while True:
        e = q.pop_min()
        if e is None:
            return out
        i, p = e
        if out and out[-1][0] == p:
            out[-1][1].append(i)
        else:
            out.append((p, [i]))


def main():
    print("# LEMON heapSortTest (PQ-20)")
    q = IPQ(14)
    for i, p in enumerate(LEMON_SEQ):
        q.insert(i, p)
    pops = [q.pop_min() for _ in range(14)]
    print("pops (index, priority):", pops)

    print("\n# LEMON heapIncreaseTest (PQ-21)")
    q = IPQ(14)
    for i, p in enumerate(LEMON_SEQ):
        q.insert(i, p)
    v = [LEMON_SEQ[i] + LEMON_INC[i] for i in range(14)]
    for i in range(14):
        q.update_priority(i, v[i])
    print("increased priorities:", v)
    print("groups:", pop_groups(q))

    print("\n# LEMON dijkstraHeapTest graph from node 3 (PQ-22)")
    dist, order = dijkstra(10, LEMON_ARCS, 3)
    bf = bellman_ford(10, LEMON_ARCS, 3)
    assert dist == bf
    print("dist:", dist)
    print("settle order:", order)
    for d in (2, 3, 8):
        assert dijkstra(10, LEMON_ARCS, 3, lambda n, d=d: IPQ(n, d=d))[0] == bf

    print("\n# igraph 2wheap hand-made trace (PQ-23)")
    q = IPQ(21)
    nv = Naive(21)
    trace = []
    for op in IGRAPH_TRACE:
        if op[0] == "push":
            q.insert(op[1], op[2]); nv.insert(op[1], op[2])
        elif op[0] == "mod":
            assert nv.pr.get(op[1]) is not None, f"MOD on absent {op[1]}"
            assert op[2] <= nv.pr[op[1]]
            q.decrease_priority(op[1], op[2]); nv.set(op[1], op[2])
        else:
            m, ties = nv.min_set()
            i, p = q.pop_min()
            assert p == m and i in ties
            nv.remove(i)
            trace.append((p, sorted(ties), i))
        assert q.valid()
    print("pops (priority, tied candidates, reference pick):")
    for t in trace:
        print("  ", t)
    print("left in queue:", sorted(nv.pr.items()), "count", q.count)

    print("\n# 10^6 permutation (PQ-34)")
    n = 10 ** 6
    inv = pow(7919, -1, n)
    print("inverse of 7919 mod 10^6:", inv, "; pops k -> index", "(k * %d) %% 10^6" % inv)
    print("first five pops:", [((k * inv) % n, k) for k in range(5)])
    print("last pop:", ((n - 1) * inv % n, n - 1))

    print("\n# random differential (PQ-30) sanity: 2000 runs against Naive")
    checks = differential(runs=2000)
    print("checks passed:", checks)


def differential(runs=2000, make=lambda n: IPQ(n), seed0=1):
    checks = 0
    for seed in range(seed0, seed0 + runs):
        rnd = random.Random(seed)
        n = rnd.choice([1, 2, 3, 5, 10, 50, 200])
        q = make(n)
        nv = Naive(n)
        for _ in range(4 * n + 10):
            i = rnd.randrange(n)
            r = rnd.random()
            p = rnd.randrange(8) if rnd.random() < 0.5 else rnd.randrange(10 ** 6)
            if r < 0.35:
                if i in nv.pr:
                    continue
                q.insert(i, p); nv.insert(i, p)
            elif r < 0.5:
                if i not in nv.pr:
                    continue
                p = min(p, nv.pr[i])
                q.decrease_priority(i, p); nv.set(i, p)
            elif r < 0.6:
                if i not in nv.pr:
                    continue
                assert q.update_priority(i, p) == nv.set(i, p); checks += 1
            elif r < 0.7:
                assert q.remove(i) == nv.remove(i); checks += 1
            else:
                m, ties = nv.min_set()
                e = q.pop_min()
                if m is None:
                    assert e is None
                else:
                    assert e[1] == m and e[0] in ties
                    nv.remove(e[0])
                checks += 1
            assert q.count == len(nv.pr)
            for j in range(n):
                assert q.contains(j) == (j in nv.pr)
                assert q.priority_of(j) == nv.pr.get(j)
            checks += 2 * n + 1
            m, ties = nv.min_set()
            assert (q.min is None) if m is None else (q.min[1] == m and q.min[0] in ties)
    return checks


if __name__ == "__main__":
    main()
