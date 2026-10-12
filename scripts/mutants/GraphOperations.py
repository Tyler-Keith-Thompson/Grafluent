# Planted bugs for GraphOperations; run with `just mutate GraphOperations`. See scripts/mutate.py.
#
# Scope: the `checked:` lookups on the views, so far: the directed complement's checked endpoint
# reads, and the GraphProtocols defaults (`contains(_:)`, then the trapping read) that the views
# reach; and a subgraph view's attached-map reads, each membership check dropped. The views' own
# rows, edges and indices have no mutants here yet.
#
# Known equivalent mutants: none.

TESTS = ["GraphOperationsTests", "GraphProtocolsTests"]

C = "ComplementView+DirectedGraph.swift"
SD = "SubgraphView+DirectedGraph.swift"
SU = "SubgraphView+Graph.swift"
L = "CheckedLookups.swift"

MUTANTS = [
    # The directed complement: a cell is an edge when both ends are in range, distinct, and unjoined.
    Mutant("celledgesourcerange", C, "UInt(bitPattern: position.source) < n", "true"),
    Mutant("celledgetargetrange", C, "UInt(bitPattern: position.target) < n", "true"),
    Mutant("celledgediagonal", C, "position.source != position.target", "true"),
    Mutant("celledgejoined", C, "return !base.contains(edge: edge)", "return true", mode="stmt"),
    Mutant("checkedsourcenoguard", C, "guard _isEdge(position) else { throw EdgeNotFound() }", "", mode="stmt", nth=0),
    Mutant("checkedtargetnoguard", C, "guard _isEdge(position) else { throw EdgeNotFound() }", "", mode="stmt", nth=1),
    Mutant("checkedtargetreadssource", C, "return target(ofEdgeAt: position)", "return source(ofEdgeAt: position)", mode="stmt"),
    # The GraphProtocols defaults: each guard dropped (the view then traps or answers for a
    # non-vertex), and each read swapped for its neighbour.
    Mutant("defsuccessors", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=0, module="GraphProtocols"),
    Mutant("defoutedges", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=1, module="GraphProtocols"),
    Mutant("defoutdegree", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=2, module="GraphProtocols"),
    Mutant("defvertexindex", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=3, module="GraphProtocols"),
    Mutant("defpredecessors", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=4, module="GraphProtocols"),
    Mutant("definedges", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=5, module="GraphProtocols"),
    Mutant("defindegree", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=6, module="GraphProtocols"),
    Mutant("defdegree", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=7, module="GraphProtocols"),
    Mutant("defneighbors", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=8, module="GraphProtocols"),
    Mutant("defincidentedges", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=9, module="GraphProtocols"),
    Mutant("defudegree", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=10, module="GraphProtocols"),
    Mutant("defuvertexindex", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=11, module="GraphProtocols"),
    Mutant("defoutdegreeread", L, "return outDegree(of: vertex)", "return outDegree(of: vertex) &+ 1", mode="stmt", module="GraphProtocols"),
    Mutant("definedegreeread", L, "return inDegree(of: vertex)", "return outDegree(of: vertex)", mode="stmt", module="GraphProtocols"),
    Mutant("defdegreeread", L, "return degree(of: vertex)", "return inDegree(of: vertex)", mode="stmt", nth=0, module="GraphProtocols"),
    Mutant("defudegreeread", L, "return degree(of: vertex)", "return degree(of: vertex) &+ 1", mode="stmt", nth=1, module="GraphProtocols"),
    # A subgraph view's map reads: each check that the vertex or edge is the view's dropped (the
    # read then answers with the base's value), directed and undirected.
    Mutant("dmapvertex", SD, "if !_new.isEmpty { _ = _viewIndex(base.vertexIndex(of: vertex)) }", "", mode="stmt"),
    Mutant("dmapcheckedvertex", SD, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt"),
    Mutant("dmapedge", SD, "precondition(_keeps(position), \"\\(position) is not an edge of the subgraph\")", "", mode="stmt"),
    Mutant("dmapcheckededge", SD, "guard _keeps(position) else { throw EdgeNotFound() }", "", mode="stmt"),
    Mutant("umapvertex", SU, "if !_new.isEmpty { _ = _viewIndex(base.vertexIndex(of: vertex)) }", "", mode="stmt"),
    Mutant("umapcheckedvertex", SU, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt"),
    Mutant("umapedge", SU, "precondition(_keepsEdge(position), \"\\(position) is not an edge of the subgraph\")", "", mode="stmt"),
    Mutant("umapcheckededge", SU, "guard _keepsEdge(position) else { throw EdgeNotFound() }", "", mode="stmt"),
]
