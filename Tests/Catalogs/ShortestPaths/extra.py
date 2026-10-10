import io, contextlib
from ref import *
with contextlib.redirect_stdout(io.StringIO()):
    from cases import und, XG
def rot(c):
    i=c.index(min(c)); return c[i:]+c[:i]
def bf(vs, es, srcs):
    g=G(vs,es); r=bellman_ford(g,srcs)
    if r[0]=="cycle": return "cycle", lab(g, rot(r[1]))
    return "tree", {g.label(i):r[1][i] for i in range(g.n)}, {g.label(i):(None if r[2][i] is None else (g.label(r[2][i]), r[3][i])) for i in range(g.n)}
jgnr = [("1","2",1),("2","3",1),("3","4",1),("5","4",1),("5","6",-1),("6","7",-1),("7","5",-1)]
V7=["1","2","3","4","5","6","7"]
print("SP-58 whole", bf(V7, jgnr, V7))
dG = [[0,3,3,0,0],[0,0,0,2,4],[0,0,0,0,0],[1,0,0,0,0],[2,0,0,2,0]]
sc = [(i,j,dG[i][j]) for i in range(5) for j in range(5) if dG[i][j]]
for s in range(5):
    g=G(range(5),sc,"ascending"); d,p,pe=bfs(g,[s]); print("SP-88",s,d,p,pe)
g=G([],und([(0,1,1),(1,2,1),(2,3,1),(3,4,1)])); print("SP-87", bfs(g,[0,4]))
g=G([],XG); print("SP-85", lab(g,list(range(g.n))), bfs(g,["s"]))
g=G([],und([(0,1,1),(1,2,1),(2,3,1),(3,0,1)])); print("SP-86", bfs(g,[0]))
pd=[(0,1,1),(1,2,1),(2,3,1),(3,0,1),(4,5,1),(1,4,1),(5,6,1),(6,7,1),(7,4,1)]
g=G(range(9),pd); print("SP-89", bfs(g,[1]))
# SP-23 two sources paths
g=G([],und([(0,1,1),(1,2,1),(2,3,10),(3,4,1)])); d,p,pe=dijkstra(g,[0,4]); print("SP-23", d, [lab(g,path_to(p,g.index[v])) for v in range(5)])
# lasso and long cycle small
n=10
print("long", bf(range(n), [(i,i+1,1) for i in range(n-1)]+[(n-1,0,-n)], [0]))
print("lasso", bf(range(n), [(i,i+1,1) for i in range(n-1)]+[(n-1,n//2,-n)], [0]))
# SP-12
g=G(range(3),[(0,0,0),(0,1,2),(1,1,0),(1,2,1)]); print("SP-12", dijkstra(g,[0]), determined_parents(g,[0],dijkstra(g,[0])[0]))
g=G(range(4),[(0,1,0),(1,2,0),(2,1,0),(2,3,1)]); d=dijkstra(g,[0])[0]; print("SP-17", d, determined_parents(g,[0],d))
g=G(range(4),[(0,1,1),(0,2,3),(1,3,3),(2,3,1)]); d=dijkstra(g,[0])[0]; print("SP-19", d, determined_parents(g,[0],d))
# SP-15 a-b 100, 110 pseudograph
g=G([],und([("a","b",100),("a","b",110)])); d=dijkstra(g,["a"]); print("SP-15", d, determined_parents(g,["a"],d[0]))
g=G([],und([("a","b",110),("a","b",100)])); d=dijkstra(g,["a"]); print("SP-15b", d, determined_parents(g,["a"],d[0]))
# SP-36, 39
g=G([],[("s","a",1),("b","c",-1)]); 
# SP-55 
print("SP-55", bf(range(3), und([(1,0,11)]), [0]))
# SP-79 sums
print(0.68+0.67, 0.18+0.50+0.67, (0.18+0.50)+0.67 == 1.35, 0.68+0.67==1.35)
# SP-24
g=G([0,1],[(0,1,0)]); print("SP-24", dijkstra(g,[0,1]))
