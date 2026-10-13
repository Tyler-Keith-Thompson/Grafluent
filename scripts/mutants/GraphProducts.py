# Planted bugs for GraphProducts; run with `just mutate GraphProducts`. See scripts/mutate.py.
#
# Scope: the products' `checked:` lookups. The products have none of their own: they are
# GraphProtocols' defaults (`contains(_:)`, then the trapping read), planted here and run against
# the product suite, which reaches every one of them on a directed or an undirected product. The
# products' own rows, edges and indices have no mutants.
#
# Known equivalent mutants: none.

TESTS = ["GraphProductsTests"]

L = "CheckedLookups.swift"
G = "guard contains(vertex) else { throw VertexNotFound() }"

MUTANTS = [
    Mutant("defsuccessors", L, G, "", mode="stmt", nth=0, module="GraphProtocols"),
    Mutant("defoutedges", L, G, "", mode="stmt", nth=1, module="GraphProtocols"),
    Mutant("defoutdegree", L, G, "", mode="stmt", nth=2, module="GraphProtocols"),
    Mutant("defvertexindex", L, G, "", mode="stmt", nth=3, module="GraphProtocols"),
    Mutant("defpredecessors", L, G, "", mode="stmt", nth=4, module="GraphProtocols"),
    Mutant("definedges", L, G, "", mode="stmt", nth=5, module="GraphProtocols"),
    Mutant("defindegree", L, G, "", mode="stmt", nth=6, module="GraphProtocols"),
    Mutant("defdegree", L, G, "", mode="stmt", nth=7, module="GraphProtocols"),
    Mutant("defneighbors", L, G, "", mode="stmt", nth=8, module="GraphProtocols"),
    Mutant("defincidentedges", L, G, "", mode="stmt", nth=9, module="GraphProtocols"),
    Mutant("defudegree", L, G, "", mode="stmt", nth=10, module="GraphProtocols"),
    Mutant("defuvertexindex", L, G, "", mode="stmt", nth=11, module="GraphProtocols"),
    Mutant("defoutdegreeread", L, "return outDegree(of: vertex)", "return outDegree(of: vertex) &+ 1", mode="stmt", module="GraphProtocols"),
    Mutant("defindegreeread", L, "return inDegree(of: vertex)", "return outDegree(of: vertex)", mode="stmt", module="GraphProtocols"),
    Mutant("defdegreeread", L, "return degree(of: vertex)", "return inDegree(of: vertex)", mode="stmt", nth=0, module="GraphProtocols"),
    Mutant("defudegreeread", L, "return degree(of: vertex)", "return degree(of: vertex) &+ 1", mode="stmt", nth=1, module="GraphProtocols"),
]
