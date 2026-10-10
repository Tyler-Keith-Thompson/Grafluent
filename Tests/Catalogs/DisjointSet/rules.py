"""Representatives under each library's linking rule (find never changes a root)."""
def sim(n, pairs, by, tie):
    par = list(range(n)); w = [1 if by == "size" else 0] * n
    def f(x):
        while par[x] != x: x = par[x]
        return x
    for a, b in pairs:
        ra, rb = f(a), f(b)
        if ra == rb: continue
        if w[ra] != w[rb]:
            win, lose = (ra, rb) if w[ra] > w[rb] else (rb, ra)
        else:
            win = {"first": ra, "second": rb, "min": min(ra, rb)}[tie]; lose = rb if win == ra else ra
        par[lose] = win
        if by == "size": w[win] += w[lose]
        elif w[win] == w[lose]: w[win] += 1
    return [f(x) for x in range(n)]
rules = {"Grafluent/scipy (size, tie smaller index)": ("size", "min"),
         "petgraph (rank, tie first arg)": ("rank", "first"),
         "Boost link_sets (rank, tie second arg)": ("rank", "second"),
         "JGraphT (rank, tie first arg)": ("rank", "first"),
         "LEMON UnionFind (size, tie second arg)": ("size", "second"),
         "Connectivity _joinEndpoints (size, tie first arg)": ("size", "first")}
cases = {"boost example": (6, [(0,1),(1,2),(3,4)]),
         "petgraph uf_test": (8, [(0,1),(1,3),(1,4),(4,7),(5,6)]),
         "jgrapht": (5, [(0,1),(2,3),(2,4),(2,4),(0,4)]),
         "scipy backwards n=10": (10, [(i,i+1) for i in range(8,-1,-1)]),
         "union(3,1) n=4": (4, [(3,1)])}
for c,(n,p) in cases.items():
    print("==", c)
    for r,(by,tie) in rules.items(): print("  ", r.ljust(52), sim(n,p,by,tie))
