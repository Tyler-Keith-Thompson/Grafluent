# Planted bugs for Connectivity's undirected half; run with `just mutate Connectivity`. See
# scripts/mutate.py.
#
# Known equivalent mutants (they survive by design):
#   firsttree    Records every search tree's size, not just the first's. The predicates search
#                only the first tree (firstTreeOnly), so the size they read is unchanged.
#   unionbysize  Drops union by size in connected components: the components are the same, only
#                the trees deeper.
#   rowcheck     Drops part of the validation of `_withIncidentIndexRows`' tables: only a
#                representation's own (underscored, untestable through the public API) rows reach
#                it, and UndirectedAdjacencyList's are consistent by construction.

TESTS = ["ConnectivityTests"]

MUTANTS = [
    # The search
    Mutant("parentvertex", "Biconnectivity.swift",
           "e == parentEdge[v]",
           "(frames.count >= 2 && w == frames[frames.count - 2].v)", nth=0),
    Mutant("lowfromlow", "Biconnectivity.swift",
           "if disc[w] < low[v] { low[v] = disc[w] }",
           "if low[w] < low[v] { low[v] = low[w] }", mode="stmt"),
    Mutant("backedgetwice", "Biconnectivity.swift",
           "disc[w] < disc[v]",
           "disc[w] != disc[v]"),
    Mutant("pointgt", "Biconnectivity.swift",
           "low[v] >= disc[p]",
           "low[v] > disc[p]"),
    Mutant("bridgegeq", "Biconnectivity.swift",
           "low[v] > disc[p]",
           "low[v] >= disc[p]", nth=0),
    Mutant("rootrule", "Biconnectivity.swift",
           "rootChildren >= 2",
           "rootChildren >= 1"),
    Mutant("rootnotexcluded", "Biconnectivity.swift",
           "p != root",
           "true"),
    Mutant("blockpopshort", "Biconnectivity.swift",
           "if e == parentEdge[v] { break }",
           "break", mode="stmt"),
    Mutant("lowpropagation", "Biconnectivity.swift",
           "                if low[v] < low[p] { low[p] = low[v] }",
           "", mode="stmt"),
    Mutant("biedgepop", "Biconnectivity.swift",
           "                            if x == v { break }",
           "                            break", mode="stmt"),
    Mutant("firsttree", "Biconnectivity.swift",
           "            if root == 0 { result.firstTreeSize = treeSize }",
           "            result.firstTreeSize = treeSize", mode="stmt"),
    Mutant("firsttreeonly", "Biconnectivity.swift",
           "firstTreeOnly && root > 0",
           "false"),
    Mutant("relabel", "Biconnectivity.swift",
           "        labels[i] = map[labels[i]]",
           "", mode="stmt"),

    Mutant("biedgetreeend", "Biconnectivity.swift",
           "                for x in vertexStack { result.biEdgeLabel[x] = label }",
           "", mode="stmt"),
    Mutant("rootchildren", "Biconnectivity.swift",
           "                        if v == root { rootChildren += 1 }",
           "                        rootChildren += 1", mode="stmt"),
    Mutant("treeedgesonly", "Biconnectivity.swift",
           """                        if wantBlocks {
                            edgeStack.append(e)
                            childStack.append(-1)
                        }""",
           "", mode="stmt"),
    Mutant("blockmembers", "Biconnectivity.swift",
           """                                result.memberBlock.append(label)
                                result.memberVertex.append(child)""",
           "", mode="stmt"),
    Mutant("blockparentmember", "Biconnectivity.swift",
           """                        result.memberBlock.append(label)
                        result.memberVertex.append(p)""",
           "", mode="stmt"),

    # Rows and components
    Mutant("componentslimit", "UndirectedRows.swift",
           "joins < limit",
           "joins < limit - 1", nth=0),
    Mutant("unionbysize", "UndirectedRows.swift",
           "                    if parent[a] > parent[b] { swap(&a, &b) }",
           "", mode="stmt"),
    Mutant("rowcheck", "UndirectedRows.swift",
           "nl == el && nl >= 0",
           "nl >= 0"),
    Mutant("lazylength", "UndirectedRows.swift",
           '                precondition(edges.count == neighbors.count, "neighborIndices and incidentEdges differ in length")',
           "", mode="stmt"),
    Mutant("lazyedgeindex", "UndirectedRows.swift",
           "indexedEdges ? graph.edgeIndex(of: position) : edgeNumbers[position]!",
           "indexedEdges ? 0 : edgeNumbers[position]!"),
    Mutant("edgenumbers", "UndirectedRows.swift",
           "for (k, position) in edges.indices.enumerated() { numbers[position] = k }",
           "for (k, position) in edges.indices.reversed().enumerated() { numbers[position] = k }", mode="stmt"),

    # Results
    Mutant("isconnectedempty", "UndirectedConnectivity.swift",
           "        guard n > 0 else { return false }",
           "        guard n > 0 else { return true }", mode="stmt"),
    Mutant("biconnectedsize", "UndirectedConnectivity.swift",
           "        guard n >= 2 else { return false }",
           "        guard n >= 1 else { return false }", mode="stmt", nth=0),
    Mutant("biedgesize", "UndirectedConnectivity.swift",
           "        guard n >= 2 else { return false }",
           "        guard n >= 1 else { return false }", mode="stmt", nth=1),
    Mutant("biconnectedreach", "UndirectedConnectivity.swift",
           "!search.stoppedEarly && search.firstTreeSize == n",
           "!search.stoppedEarly", nth=0),
    Mutant("vertexblockorder", "UndirectedConnectivity.swift",
           "_countingSort(byBlock, by: memberVertex, keyCount: n)",
           "_countingSort(Array(memberBlock.indices.reversed()), by: memberVertex, keyCount: n)"),
    Mutant("memberorder", "UndirectedConnectivity.swift",
           "_countingSort(byVertex, by: memberBlock, keyCount: count)",
           "_countingSort(Array(memberBlock.indices.reversed()), by: memberBlock, keyCount: count)"),
    Mutant("loopblock", "UndirectedConnectivity.swift",
           "        return label >= 0 ? label : nil",
           "        return label", mode="stmt"),
    Mutant("treepoints", "UndirectedConnectivity.swift",
           "                if p >= 0 { blockPoints.append(p) }",
           "                blockPoints.append(Swift.max(p, 0))", mode="stmt"),
    Mutant("nodeorder", "UndirectedConnectivity.swift",
           "        if _pointNumber[v] >= 0 { return .articulationPoint(_pointNumber[v]) }",
           "", mode="stmt"),
]
