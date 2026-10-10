"""Reference models for the DisjointSet catalog.

DS   -- the recommended design: one array, a root holds minus its set's size, any other element
        its parent; union by size, ties won by the root with the smaller index (scipy's rule);
        find by path halving. Iterative.
Naive -- an independent oracle: owner[x] = set id, members per set, and the representative of
        each set maintained by the rule from the sizes and representatives alone.
"""


class DS:
    def __init__(self, n=0):
        self.p = [-1] * n
        self.sets = n

    def __len__(self):
        return len(self.p)

    def make_set(self):
        self.p.append(-1)
        self.sets += 1
        return len(self.p) - 1

    def _check(self, x):
        if not (0 <= x < len(self.p)):
            raise IndexError(x)

    def find(self, x):
        self._check(x)
        p = self.p
        while p[x] >= 0:
            q = p[x]
            if p[q] < 0:
                return q
            p[x] = p[q]  # halving: point at the grandparent, then jump there
            x = p[x]
        return x

    def find_readonly(self, x):
        self._check(x)
        while self.p[x] >= 0:
            x = self.p[x]
        return x

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra == rb:
            return False
        p = self.p
        # winner: larger size; on a tie the smaller index
        if -p[ra] < -p[rb] or (p[ra] == p[rb] and rb < ra):
            ra, rb = rb, ra
        p[ra] += p[rb]
        p[rb] = ra
        self.sets -= 1
        return True

    def in_same_set(self, a, b):
        return self.find(a) == self.find(b)

    def set_size(self, x):
        return -self.p[self.find(x)]

    def labeling(self):
        lab = [-1] * len(self.p)
        k = 0
        for x in range(len(self.p)):
            r = self.find_readonly(x)
            if lab[r] < 0:
                lab[r] = k
                k += 1
            lab[x] = lab[r]
        return lab

    def subsets(self):
        lab = self.labeling()
        out = [[] for _ in range(self.sets)]
        for x, l in enumerate(lab):
            out[l].append(x)
        return out

    def reps(self):
        return [self.find_readonly(x) for x in range(len(self.p))]


class Naive:
    def __init__(self, n=0):
        self.owner = list(range(n))
        self.members = {i: [i] for i in range(n)}
        self.rep = {i: i for i in range(n)}

    def make_set(self):
        x = len(self.owner)
        self.owner.append(x)
        self.members[x] = [x]
        self.rep[x] = x
        return x

    def find(self, x):
        if not (0 <= x < len(self.owner)):
            raise IndexError(x)
        return self.rep[self.owner[x]]

    def union(self, a, b):
        sa, sb = self.owner[a], self.owner[b]
        if sa == sb:
            return False
        ra, rb = self.rep[sa], self.rep[sb]
        za, zb = len(self.members[sa]), len(self.members[sb])
        winner = ra if (za > zb or (za == zb and ra < rb)) else rb
        for x in self.members[sb]:
            self.owner[x] = sa
        self.members[sa] += self.members.pop(sb)
        del self.rep[sb]
        self.rep[sa] = winner
        return True

    def set_size(self, x):
        return len(self.members[self.owner[x]])

    @property
    def sets(self):
        return len(self.members)

    def subsets(self):
        seen, out = set(), []
        for x in range(len(self.owner)):
            s = self.owner[x]
            if s not in seen:
                seen.add(s)
                out.append(sorted(self.members[s]))
        return out

    def labeling(self):
        ids, lab = {}, []
        for x in range(len(self.owner)):
            s = self.owner[x]
            if s not in ids:
                ids[s] = len(ids)
            lab.append(ids[s])
        return lab
