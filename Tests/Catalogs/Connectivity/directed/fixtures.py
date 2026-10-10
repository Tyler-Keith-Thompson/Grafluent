import re
E = lambda *pairs: list(pairs)
F = {}
def fx(name, edges, listed=()):
    F[name] = dict(edges=list(edges), listed=list(listed))
fx('empty', [])
fx('trivial', [], [0])
fx('singleSelfLoop', [(0,0)])
fx('isolatedVertices', [], range(10))
fx('directedPath3', [(0,1),(1,2)])
fx('completeDirected3', [(0,1),(0,2),(1,0),(1,2),(2,0),(2,1)])
fx('completeDirected10', [(u,v) for u in range(10) for v in range(10) if u!=v])
fx('networkXFunctionGraph', [(0,1),(0,2),(0,3),(1,1),(1,2),(1,0)], [4])  # 4 listed after edges in builder; order matters for Multigraph only
fx('house', [(5,3),(3,4),(3,2),(4,0),(4,1),(2,1),(1,0)])
fx('scc9', [(6,0),(0,3),(3,6),(8,6),(8,2),(2,5),(5,8),(7,5),(1,7),(7,4),(4,1)])
fx('selfLoopsAndDuplicates', [(1,2),(2,3),(2,3),(2,4),(4,4),(5,5),(5,2),(5,5)])
fx('directedCycle4', [(1,2),(2,3),(3,4),(4,1)])
fx('triangleWithReciprocalEdge', [(1,2),(2,1),(2,3),(3,1)])
fx('pathWithChord', [(v,v+1) for v in range(5)] + [(1,3),(1,3)])
pet=[]
for i in range(5):
    nxt=(i+1)%5; skip=5+(i+2)%5
    pet += [(i,nxt),(nxt,i),(i,i+5),(i+5,i),(i+5,skip),(skip,i+5)]
fx('petersen', pet)
fx('cube', [(v, v^(1<<b)) for v in range(8) for b in range(3)])
fx('directedPath10', [(v,v+1) for v in range(9)])
fx('directedCycle10', [(v,(v+1)%10) for v in range(10)])
fx('boostExample', [(1,2),(1,5),(2,0),(2,2),(3,4),(4,3),(5,0)], [0])
fx('boost24', [(1,2),(2,10),(2,5),(3,10),(3,0),(4,5),(4,0),(5,14),(6,3),(7,17),(7,11),(8,17),(8,1),(9,11),(9,1),(10,19),(10,15),(10,8),(11,19),(11,15),(11,4),(12,19),(12,8),(12,4),(13,15),(13,8),(13,4),(14,22),(14,12),(15,22),(15,6),(16,12),(16,6),(17,20),(18,9),(19,23),(19,18),(20,23),(20,13),(21,18),(21,13),(22,21),(23,16)])
fx('petgraphEdgesDirected', [(0,5),(0,2),(0,3),(0,1),(1,3),(2,3),(2,4),(4,0),(6,6)])
fx('igraphReverseEdges', [(0,1),(1,2),(2,3),(3,1),(1,4)])
fx('jgraphtMatrixCSV', [(0,1),(0,2),(2,0),(2,3),(3,4),(4,0),(4,1),(4,2),(4,3),(4,4)])
fx('boostCsrUnsorted', [(5,0),(3,2),(4,1),(4,0),(0,2),(5,2)])
fx('boostWebGraph', [(0,1),(0,2),(0,3),(1,0),(1,3),(1,5),(2,0),(2,5),(3,1),(3,4),(4,1),(5,0),(5,2)])
fx('petgraphCsr1', [(0,0),(1,2),(2,2),(0,2),(1,0),(1,1)])
fx('petgraphCsrFrom', [(0,1),(0,2),(1,0),(1,1),(2,2),(2,4)], [3])
fx('petgraphBellmanFord', [(0,1),(0,2),(1,0),(1,1),(1,2),(1,3),(2,3),(4,5),(5,7),(6,7),(7,8)])
fx('neo4jDirected', [(0,1),(0,2),(1,2),(1,3),(2,4),(3,4)])
fx('jgraphtSparseDirected', [(0,1),(1,0),(1,4),(1,5),(1,6),(2,4),(2,4),(2,4),(3,4),(4,5),(5,6),(7,6),(7,7)])
fx('scipyConstructor2', [(3,4)], [0,1,2,5])
fx('networkXABCD', [('A','B'),('A','C'),('B','D'),('B','C'),('C','D')], ['G','J','K'])
fx('petgraphDAG', [('a','b'),('a','d'),('d','b'),('b','c'),('b','e'),('c','e'),('d','e'),('d','f'),('f','e'),('f','g'),('e','g')])

def realworld():
    src = open(__import__('os').path.join(__import__('os').path.dirname(__import__('os').path.abspath(__file__)), '..', '..', '..', 'GrafluentTestSupport', 'RealWorldFixtures.swift')).read()
    out = {}
    for m in re.finditer(r'public static let (\w+): DirectedFixture<Int> = \{(.*?)\n    \}\(\)', src, re.S):
        name, body = m.group(1), m.group(2)
        s = [int(x) for x in re.findall(r'-?\d+', re.search(r'let sources: \[Int\] = \[(.*?)\]', body, re.S).group(1))]
        t = [int(x) for x in re.findall(r'-?\d+', re.search(r'let targets: \[Int\] = \[(.*?)\]', body, re.S).group(1))]
        n = int(re.search(r'vertexCount: (\d+)', body).group(1))
        out[name] = dict(edges=list(zip(s,t)), listed=list(range(n)))
    return out
F.update(realworld())

def vertex_set(f):
    s = set(f['listed'])
    for u,v in f['edges']: s.add(u); s.add(v)
    return s
def succ_sorted(f):
    S = {v: [] for v in vertex_set(f)}
    for u,v in sorted(set(f['edges'])): S[u].append(v)
    return S
