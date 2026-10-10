import os, re, sys
names={'D':'discover','T':'treeEdge','N':'nonTreeEdge','B':'backEdge','F':'forwardEdge','C':'crossEdge','X':'finish'}
def expand(compact):
    out=[]
    for tok in compact.split():
        c,rest=tok[0],tok[1:]
        out.append(f'{names[c]}({rest})')
    return ' '.join(out)
def sym(pairs): 
    e=[]
    for a,b in pairs: e+= [(a,b),(b,a)]
    return sorted(e)
def edges_swift(edges, s=False):
    q=(lambda v: f'"{v}"') if s else str
    return '[' + ', '.join(f'DirectedEdge(from: {q(a)}, to: {q(b)})' for a,b in edges) + ']'
tests=[]
def fixture_test(id, title, fixture, call, compact, kind, vc=None):
    vc = vc or f'DirectedFixture<Int>.{fixture}.vertexCount'
    edges=f'DirectedFixture<Int>.{fixture}.edges'
    tests.append((id,title,f'''        let edges = {edges}
        let expected = "{expand(compact)}"
        let matrix = AdjacencyMatrix(vertexCount: {vc}, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: {vc}, edges: edges)
        #expect(matrix.{call}.map(\\.description).joined(separator: " ") == expected)
        #expect(sparse.{call}.map(\\.description).joined(separator: " ") == expected)''', kind))
def inline_test(id,title,n,edges,call,compact,kind,comment=None):
    c=f'        // {comment}\n' if comment else ''
    tests.append((id,title,f'''{c}        let edges = {edges_swift(edges)}
        let expected = "{expand(compact)}"
        let matrix = AdjacencyMatrix(vertexCount: {n}, edges: edges)
        let sparse = CompressedSparseRow(vertexCount: {n}, edges: edges)
        #expect(matrix.{call}.map(\\.description).joined(separator: " ") == expected)
        #expect(sparse.{call}.map(\\.description).joined(separator: " ") == expected)''',kind))
def multi_test(id,title,build,call,compact,kind,comment=None):
    c=f'        // {comment}\n' if comment else ''
    tests.append((id,title,f'''{c}        let graph = {build}
        #expect(graph.{call}.map(\\.description).joined(separator: " ") == "{expand(compact)}")''',kind))
B='bfs'; Dk='dfs'
# A. BFS
fixture_test('TR-01','a single vertex is discovered and finished','trivial','breadthFirstSearch(from: 0)','D0 X0',B, vc='1')
fixture_test('TR-02','a path: a vertex finishes after its last out-edge','directedPath3','breadthFirstSearch(from: 0)','D0 T0→1 D1 X0 T1→2 D2 X1 X2',B)
fixture_test('TR-03','a complete digraph: every edge out of a reached vertex is reported once','completeDirected3','breadthFirstSearch(from: 0)','D0 T0→1 D1 T0→2 D2 X0 N1→0 N1→2 X1 N2→0 N2→1 X2',B)
fixture_test('TR-04','a self-loop is a non-tree edge','singleSelfLoop','breadthFirstSearch(from: 0)','D0 N0→0 X0',B)
fixture_test('TR-05','a self-loop among other out-edges','networkXFunctionGraph','breadthFirstSearch(from: 0)','D0 T0→1 D1 T0→2 D2 T0→3 D3 X0 N1→0 N1→1 N1→2 X1 X2 X3',B)
fixture_test('TR-06','a DAG from its source','house','breadthFirstSearch(from: 5)','D5 T5→3 D3 X5 T3→2 D2 T3→4 D4 X3 T2→1 D1 X2 T4→0 D0 N4→1 X4 N1→0 X1 X0',B)
fixture_test('TR-07','a cyclic graph','scc9','breadthFirstSearch(from: 1)','D1 T1→7 D7 X1 T7→4 D4 T7→5 D5 X7 N4→1 X4 T5→8 D8 X5 T8→2 D2 T8→6 D6 X8 N2→5 X2 T6→0 D0 X6 T0→3 D3 X0 N3→6 X3',B)
fixture_test('TR-08','unreached vertices produce no events','petgraphEdgesDirected','breadthFirstSearch(from: 0)','D0 T0→1 D1 T0→2 D2 T0→3 D3 T0→5 D5 X0 N1→3 X1 N2→3 T2→4 D4 X2 X3 X5 N4→0 X4',B)
nxbfs=sym([(0,1),(1,2),(1,3),(2,4),(3,4)])
inline_test('TR-09',"NetworkX's TestBFS graph",5,nxbfs,'breadthFirstSearch(from: 0)','D0 T0→1 D1 X0 N1→0 T1→2 D2 T1→3 D3 X1 N2→1 T2→4 D4 X2 N3→1 N3→4 X3 N4→2 N4→3 X4',B,"NetworkX test_bfs.py, undirected, written as both directions.")
inline_test('TR-10','a directed 5-cycle with a loop',5,sorted([(i,(i+1)%5) for i in range(5)]+[(4,4)]),'breadthFirstSearch(from: 0)','D0 T0→1 D1 X0 T1→2 D2 X1 T2→3 D3 X2 T3→4 D4 X3 N4→0 N4→4 X4',B,"NetworkX test_bfs.py: tree ×4, (4, 0) reverse, (4, 4) level.")
inline_test('TR-11','a 5-cycle with chords',6,sorted([(i,(i+1)%5) for i in range(5)]+[(0,2),(1,5),(2,5)]),'breadthFirstSearch(from: 0)','D0 T0→1 D1 T0→2 D2 X0 N1→2 T1→5 D5 X1 T2→3 D3 N2→5 X2 X5 T3→4 D4 X3 N4→0 X4',B,"NetworkX test_bfs.py: 1→2 level, 2→5 forward, 4→0 reverse.")
inline_test('TR-12','every source is discovered before any edge',3,sym([(0,1),(0,2),(1,2)]),'breadthFirstSearch(from: [0, 1])','D0 D1 N0→1 T0→2 D2 X0 N1→0 N1→2 X1 N2→0 N2→1 X2',B,"NetworkX bfs_labeled_edges doctest: K3 from [0, 1].")
fixture_test('TR-13','several sources on a DAG','house','breadthFirstSearch(from: [3, 4])','D3 D4 T3→2 D2 N3→4 X3 T4→0 D0 T4→1 D1 X4 N2→1 X2 X0 N1→0 X1',B)
multi_test('TR-18','String vertices in written order','ReferenceDirectedMultigraph(vertices: DirectedFixture<String>.petgraphDAG.vertices, edges: DirectedFixture<String>.petgraphDAG.edges)','breadthFirstSearch(from: "a")','Da Ta→b Db Ta→d Dd Xa Tb→c Dc Tb→e De Xb Nd→b Nd→e Td→f Df Xd Nc→e Xc Te→g Dg Xe Nf→e Nf→g Xf Xg',B)
# C. DFS
fixture_test('TR-31','a single vertex','trivial','depthFirstSearch(from: 0)','D0 X0',Dk, vc='1')
fixture_test('TR-32','a self-loop is a back edge','singleSelfLoop','depthFirstSearch(from: 0)','D0 B0→0 X0',Dk)
fixture_test('TR-33','a path has only tree edges and finishes in reverse','directedPath3','depthFirstSearch(from: 0)','D0 T0→1 D1 T1→2 D2 X2 X1 X0',Dk)
fixture_test('TR-34','a complete digraph has back and forward edges','completeDirected3','depthFirstSearch(from: 0)','D0 T0→1 D1 B1→0 T1→2 D2 B2→0 B2→1 X2 X1 F0→2 X0',Dk)
fixture_test('TR-35','back edges to the parent and to self','networkXFunctionGraph','depthFirstSearch(from: 0)','D0 T0→1 D1 B1→0 B1→1 T1→2 D2 X2 X1 F0→2 T0→3 D3 X3 X0',Dk)
fixture_test('TR-36','a DAG has cross edges and no back edges','house','depthFirstSearch(from: 5)','D5 T5→3 D3 T3→2 D2 T2→1 D1 T1→0 D0 X0 X1 X2 T3→4 D4 C4→0 C4→1 X4 X3 X5',Dk)
fixture_test('TR-37','three strongly connected components','scc9','depthFirstSearch(from: 1)','D1 T1→7 D7 T7→4 D4 B4→1 X4 T7→5 D5 T5→8 D8 T8→2 D2 B2→5 X2 T8→6 D6 T6→0 D0 T0→3 D3 B3→6 X3 X0 X6 X8 X5 X7 X1',Dk)
fixture_test('TR-38','all four edge classes in one search','petgraphEdgesDirected','depthFirstSearch(from: 0)','D0 T0→1 D1 T1→3 D3 X3 X1 T0→2 D2 C2→3 T2→4 D4 B4→0 X4 X2 F0→3 T0→5 D5 X5 X0',Dk)
pgdv=sorted([(0,5),(0,2),(0,3),(0,1),(1,3),(2,3),(2,4),(4,0),(4,5)])
inline_test('TR-39',"petgraph's dfs_visit graph",6,pgdv,'depthFirstSearch(from: 0)','D0 T0→1 D1 T1→3 D3 X3 X1 T0→2 D2 C2→3 T2→4 D4 B4→0 T4→5 D5 X5 X4 X2 F0→3 F0→5 X0',Dk,"petgraph tests/graph.rs dfs_visit.")
nxdfs=sym([(0,1),(1,2),(1,3),(2,4),(3,0),(0,4)])
inline_test('TR-40',"NetworkX's TestDFS graph",5,nxdfs,'depthFirstSearch(from: 0)','D0 T0→1 D1 B1→0 T1→2 D2 B2→1 T2→4 D4 B4→0 B4→2 X4 X2 T1→3 D3 B3→0 B3→1 X3 X1 F0→3 F0→4 X0',Dk,"NetworkX test_dfs.py; its nontree labels are these back and forward edges.")
inline_test('TR-41','the whole of a disconnected graph',4,sym([(0,1),(2,3)]),'depthFirstSearch()','D0 T0→1 D1 B1→0 X1 X0 D2 T2→3 D3 B3→2 X3 X2',Dk,"NetworkX test_dfs.py D.")
fixture_test('TR-42','a reciprocal edge and a triangle','triangleWithReciprocalEdge','depthFirstSearch(from: 1)','D1 T1→2 D2 B2→1 T2→3 D3 B3→1 X3 X2 X1',Dk, vc='4')
fixture_test('TR-43','a directed cycle has one back edge, closing it','directedCycle4','depthFirstSearch(from: 1)','D1 T1→2 D2 T2→3 D3 T3→4 D4 B4→1 X4 X3 X2 X1',Dk, vc='5')
fixture_test('TR-44','a DAG with forward and cross edges','neo4jDirected','depthFirstSearch(from: 0)','D0 T0→1 D1 T1→2 D2 T2→4 D4 X4 X2 T1→3 D3 C3→4 X3 X1 F0→2 X0',Dk)
fixture_test('TR-45','self-loops at a root and at a leaf','petgraphCsr1','depthFirstSearch(from: 0)','D0 B0→0 T0→2 D2 B2→2 X2 X0',Dk)
multi_test('TR-46','String vertices in written order','ReferenceDirectedMultigraph(vertices: DirectedFixture<String>.petgraphDAG.vertices, edges: DirectedFixture<String>.petgraphDAG.edges)','depthFirstSearch(from: "a")','Da Ta→b Db Tb→c Dc Tc→e De Te→g Dg Xg Xe Xc Fb→e Xb Ta→d Dd Cd→b Cd→e Td→f Df Cf→e Cf→g Xf Xd Xa',Dk)
multi_test('TR-47','neighbor order changes the transcript, not its validity','ReferenceDirectedMultigraph(edges: DirectedFixture<Int>.house.edges)','depthFirstSearch(from: 5)','D5 T5→3 D3 T3→4 D4 T4→0 D0 X0 T4→1 D1 C1→0 X1 X4 T3→2 D2 C2→1 X2 X3 X5',Dk,"Written order: 3's successors are [4, 2], 4's are [0, 1]; compare TR-36.")
multi_test('TR-48',"NetworkX's ABCD graph in written order",'ReferenceDirectedMultigraph(edges: DirectedFixture<String>.networkXABCD.edges)','depthFirstSearch(from: "A")','DA TA→B DB TB→D DD XD TB→C DC CC→D XC XB FA→C XA',Dk)
fixture_test('TR-49','a symmetric graph has no cross edges','cube','depthFirstSearch(from: 0)','D0 T0→1 D1 B1→0 T1→3 D3 B3→1 T3→2 D2 B2→0 B2→3 T2→6 D6 B6→2 T6→4 D4 B4→0 T4→5 D5 B5→1 B5→4 T5→7 D7 B7→3 B7→5 B7→6 X7 X5 B4→6 X4 F6→7 X6 X2 F3→7 X3 F1→5 X1 F0→2 F0→4 X0',Dk)
fixture_test('TR-50','a row dense with self-loops','jgraphtMatrixCSV','depthFirstSearch(from: 0)','D0 T0→1 D1 X1 T0→2 D2 B2→0 T2→3 D3 T3→4 D4 B4→0 C4→1 B4→2 B4→3 B4→4 X4 X3 X2 X0',Dk)
lemon=sorted([(0,1),(1,2),(2,3),(1,4),(4,2),(4,5),(5,0),(6,3)])
inline_test('TR-51',"LEMON's test digraph",7,lemon,'depthFirstSearch(from: 0)','D0 T0→1 D1 T1→2 D2 T2→3 D3 X3 X2 T1→4 D4 C4→2 T4→5 D5 B5→0 X5 X4 X1 X0',Dk,"LEMON test/dfs_test.cc.")
# D. whole graph
fixture_test('TR-56',"the whole graph, roots in vertices' order",'house','depthFirstSearch()','D0 X0 D1 C1→0 X1 D2 C2→1 X2 D3 C3→2 T3→4 D4 C4→0 C4→1 X4 X3 D5 C5→3 X5',Dk)
fixture_test('TR-57','the whole graph with an isolated vertex and a 2-cycle','boostExample','depthFirstSearch()','D0 X0 D1 T1→2 D2 C2→0 B2→2 X2 T1→5 D5 C5→0 X5 X1 D3 T3→4 D4 B4→3 X4 X3',Dk)
fixture_test('TR-58','the whole graph: the second tree has only cross edges into the first','scc9','depthFirstSearch()','D0 T0→3 D3 T3→6 D6 B6→0 X6 X3 X0 D1 T1→7 D7 T7→4 D4 B4→1 X4 T7→5 D5 T5→8 D8 T8→2 D2 B2→5 X2 C8→6 X8 X5 X7 X1',Dk)
multi_test('TR-59','the whole graph with isolated String vertices, listed first','ReferenceDirectedMultigraph(vertices: ["G", "J", "K"], edges: DirectedFixture<String>.networkXABCD.edges)','depthFirstSearch()','DG XG DJ XJ DK XK DA TA→B DB TB→D DD XD TB→C DC CC→D XC XB FA→C XA',Dk)
fixture_test('TR-62','several roots in the order given; a reached root is skipped','house','depthFirstSearch(from: [3, 0, 5])','D3 T3→2 D2 T2→1 D1 T1→0 D0 X0 X1 X2 T3→4 D4 C4→0 C4→1 X4 X3 D5 C5→3 X5',Dk)
fixture_test('TR-63','isolated vertices only','isolatedVertices','depthFirstSearch()',' '.join(f'D{i} X{i}' for i in range(10)),Dk)
fixture_test('TR-65',"the whole of petgraph's Bellman–Ford graph",'petgraphBellmanFord','depthFirstSearch()','D0 T0→1 D1 B1→0 B1→1 T1→2 D2 T2→3 D3 X3 X2 F1→3 X1 F0→2 X0 D4 T4→5 D5 T5→7 D7 T7→8 D8 X8 X7 X5 X4 D6 C6→7 X6',Dk)
# E. multigraph
multi_test('TR-66','the second copy of a tree edge is a forward edge','ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])','depthFirstSearch()','D0 T0→1 D1 X1 F0→1 X0',Dk)
multi_test('TR-67','every copy of a self-loop is a back edge','ReferenceDirectedMultigraph(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])','depthFirstSearch()','D0 B0→0 B0→0 X0 D1 X1',Dk)
multi_test('TR-67','every copy of a self-loop is a non-tree edge in breadth-first search','ReferenceDirectedMultigraph(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])','breadthFirstSearch(from: 0)','D0 N0→0 N0→0 X0',B)
multi_test('TR-68','antiparallel and parallel edges, depth-first','ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])','depthFirstSearch()','D0 T0→1 D1 B1→0 X1 F0→1 X0',Dk)
multi_test('TR-68','antiparallel and parallel edges, breadth-first','ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])','breadthFirstSearch(from: 0)','D0 T0→1 D1 N0→1 X0 N1→0 X1',B)
multi_test('TR-69','a duplicated chord, depth-first','ReferenceDirectedMultigraph(edges: DirectedFixture<Int>.pathWithChord.edges)','depthFirstSearch()','D0 T0→1 D1 T1→2 D2 T2→3 D3 T3→4 D4 T4→5 D5 X5 X4 X3 X2 F1→3 F1→3 X1 X0',Dk)
multi_test('TR-69','a duplicated chord, breadth-first','ReferenceDirectedMultigraph(edges: DirectedFixture<Int>.pathWithChord.edges)','breadthFirstSearch(from: 0)','D0 T0→1 D1 X0 T1→2 D2 T1→3 D3 N1→3 X1 N2→3 X2 T3→4 D4 X3 T4→5 D5 X4 X5',B)
multi_test('TR-70','parallel edges and self-loop pairs','ReferenceDirectedMultigraph(edges: DirectedFixture<Int>.selfLoopsAndDuplicates.edges)','depthFirstSearch()','D1 T1→2 D2 T2→3 D3 X3 F2→3 T2→4 D4 B4→4 X4 X2 X1 D5 B5→5 C5→2 B5→5 X5',Dk)
multi_test('TR-71','a tripled cross edge is three cross events','ReferenceDirectedMultigraph(edges: DirectedFixture<Int>.jgraphtSparseDirected.edges)','depthFirstSearch()','D0 T0→1 D1 B1→0 T1→4 D4 T4→5 D5 T5→6 D6 X6 X5 X4 F1→5 F1→6 X1 X0 D2 C2→4 C2→4 C2→4 X2 D3 C3→4 X3 D7 C7→6 B7→7 X7',Dk)
# F. depth limit
fixture_test('TR-73','depth limit 0 reports only the sources, depth-first','house','depthFirstSearch(from: 5, depthLimit: 0)','D5 X5',Dk)
fixture_test('TR-73','depth limit 0 reports only the sources, breadth-first','house','breadthFirstSearch(from: 5, depthLimit: 0)','D5 X5',B)
nxtree=sym([(i,i+1) for i in range(6)]+[(2,7),(7,8),(8,9),(9,10)])
inline_test('TR-76','depth-limited transcripts',11,nxtree,'depthFirstSearch(from: 5, depthLimit: 1)','D5 T5→4 D4 X4 T5→6 D6 X6 X5',Dk,"NetworkX test_dfs.py: path 0…6 plus 2–7–8–9–10.")
inline_test('TR-76','depth-limited transcripts, from 6',11,nxtree,'depthFirstSearch(from: 6, depthLimit: 2)','D6 T6→5 D5 T5→4 D4 X4 B5→6 X5 X6',Dk,"NetworkX: (5, 4) reverse-depth_limit, (5, 6) nontree.")
inline_test('TR-80','a depth-limited breadth-first transcript',11,nxtree,'breadthFirstSearch(from: 1, depthLimit: 3)','D1 T1→0 D0 T1→2 D2 X1 N0→1 X0 N2→1 T2→3 D3 T2→7 D7 X2 N3→2 T3→4 D4 X3 N7→2 T7→8 D8 X7 X4 X8',B,"NetworkX test_bfs.py depth limit.")
# TR-79 multigraph sorted, vertices listed
dd=sym([(0,1),(2,3),(2,7),(7,8),(8,9),(9,10)])
multi_test('TR-79','depth limit 1 over the whole of a disconnected graph',f'ReferenceDirectedMultigraph(vertices: [0, 1, 2, 3, 7, 8, 9, 10], edges: {edges_swift(dd)})','depthFirstSearch(depthLimit: 1)','D0 T0→1 D1 X1 X0 D2 T2→3 D3 X3 T2→7 D7 X7 X2 D8 C8→7 T8→9 D9 X9 X8 D10 C10→9 X10',Dk,"NetworkX test_dfs.py: 8→7 and 10→9 nontree.")
lines=['''// Exact event transcripts. AdjacencyMatrix and CompressedSparseRow list successors in ascending
// order, so a search over either gives one fixed transcript; the ReferenceDirectedMultigraph test conformer gives
// written order. Expected transcripts were computed independently and checked against NetworkX.
// Case IDs (TR-nn) refer to the catalog; see README.md.
//
// GENERATED from the catalog by a script, then checked in: each test is self-contained.

import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal
''']
for kindname,suite,kind in [('Breadth-first search transcripts','BreadthFirstSearchTranscriptTests',B),('Depth-first search transcripts','DepthFirstSearchTranscriptTests',Dk)]:
    lines.append(f'@Suite("{kindname}")\nstruct {suite} {{')
    seen={}
    for id,title,body,k in tests:
        if k!=kind: continue
        fn=re.sub(r'[^A-Za-z0-9]','',id.lower().replace('-',''))
        seen[fn]=seen.get(fn,0)+1
        if seen[fn]>1: fn+=f'v{seen[fn]}'
        lines.append(f'    @Test("{id} {title}")\n    func {fn}() {{\n{body}\n    }}\n')
    lines[-1]=lines[-1].rstrip('\n')+'\n'
    lines.append('}\n')
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'TraversalTests')
open(os.path.join(OUT, 'SearchTranscriptTests.swift'),'w').write('\n'.join(lines))
print(len(tests))
