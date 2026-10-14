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
#   ke_degree    (removed) Pruning only vertices of degree below k − 1: a vertex of degree k − 1
#                cannot carry k edge-disjoint paths either, so its flows all stop below k and it
#                is still a class alone. Time only.

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
    Mutant("componentslimit", "UndirectedComponents.swift",
           "joins < limit",
           "joins < limit - 1", nth=0),
    Mutant("unionbysize", "UndirectedComponents.swift",
           "                    if parent[a] > parent[b] { swap(&a, &b) }",
           "", mode="stmt"),
    Mutant("rowcheck", "UndirectedRows.swift",
           "nl == el && nl >= 0",
           "nl >= 0", module="GraphProtocols"),
    Mutant("lazylength", "UndirectedRows.swift",
           '                precondition(edges.count == neighbors.count, "neighborIndices and incidentEdges differ in length")',
           "", mode="stmt", module="GraphProtocols"),
    Mutant("lazyedgeindex", "UndirectedRows.swift",
           "indexedEdges ? graph.edgeIndex(of: position) : edgeNumbers[position]!",
           "indexedEdges ? 0 : edgeNumbers[position]!", module="GraphProtocols"),
    Mutant("edgenumbers", "UndirectedRows.swift",
           "for (k, position) in edges.indices.enumerated() { numbers[position] = k }",
           "for (k, position) in edges.indices.reversed().enumerated() { numbers[position] = k }", mode="stmt", module="GraphProtocols"),

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

    # reuse pass (D): Arborescence(_: DominatorTree)
    Mutant("da_reached", "DominatorTree+Arborescence.swift",
           "tree._enter[v] >= 0",
           "true"),
    Mutant("df_members", "Dominators.swift",
           "order.map { vertices.vertex(members[$0]) }",
           "order.map { vertices.vertex($0) }"),
    Mutant("da_parent", "DominatorTree+Arborescence.swift",
           "parents[number[v]] = number[tree._idom[v]]",
           "parents[number[v]] = tree._idom[v]"),

    # reuse pass (C)
    Mutant("pooledcursor", "DirectedGraph.swift",
           "position &+ targetRows[3 &* row &+ 1]",
           "targetRows[3 &* row &+ 1]", module="GraphProtocols"),

    # The checked: result queries: each drops its membership check, so the
    # trapping spelling traps, or throws for a member.
    Mutant("ckcomponent", "Components.swift", "guard _vertices.graph.contains(vertex) else { throw VertexNotFound() }", "", mode="stmt"),
    Mutant("ckcomponentthrow", "Components.swift", "guard _vertices.graph.contains(vertex) else { throw VertexNotFound() }", "throw VertexNotFound()", mode="stmt"),
    Mutant("ckidom", "Dominators.swift", "guard _vertices.graph.contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=0),
    Mutant("ckidomthrow", "Dominators.swift", "guard _vertices.graph.contains(vertex) else { throw VertexNotFound() }", "throw VertexNotFound()", mode="stmt", nth=0),
    Mutant("ckdominators", "Dominators.swift", "guard _vertices.graph.contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=1),
    Mutant("ckstrict", "Dominators.swift", "guard _vertices.graph.contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=2),
    Mutant("ckstrictthrow", "Dominators.swift", "guard _vertices.graph.contains(vertex) else { throw VertexNotFound() }", "throw VertexNotFound()", mode="stmt", nth=2),
    Mutant("ckchildren", "Dominators.swift", "guard _vertices.graph.contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=3),
    Mutant("ckfrontier", "Dominators.swift", "guard _vertices.graph.contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=4),
    Mutant("ckfrontierthrow", "Dominators.swift", "guard _vertices.graph.contains(vertex) else { throw VertexNotFound() }", "throw VertexNotFound()", mode="stmt", nth=4),
    Mutant("ckdominatesa", "Dominators.swift", "_vertices.graph.contains(a)", "true"),
    Mutant("ckdominatesb", "Dominators.swift", "_vertices.graph.contains(b)", "true"),
    Mutant("ckdominatesthrow", "Dominators.swift", "_vertices.graph.contains(b)", "false"),
    Mutant("ckedgerange", "UndirectedConnectivity.swift", "guard _graph.edges.indices.contains(position) else { throw EdgeNotFound() }", "", mode="stmt"),
    Mutant("ckedgenumbers", "UndirectedConnectivity.swift", "guard _edgeNumbers[position] != nil else { throw EdgeNotFound() }", "", mode="stmt"),
    Mutant("ckedgebranch", "UndirectedConnectivity.swift", "_graph.edgeIndexBound != nil", "false", nth=1),
    Mutant("ckcontaining", "UndirectedConnectivity.swift", "guard _graph.contains(vertex) else { throw VertexNotFound() }", "", mode="stmt"),
    Mutant("ckcontainingthrow", "UndirectedConnectivity.swift", "guard _graph.contains(vertex) else { throw VertexNotFound() }", "throw VertexNotFound()", mode="stmt"),
    Mutant("cknode", "UndirectedConnectivity.swift", "guard blocks._graph.contains(vertex) else { throw VertexNotFound() }", "", mode="stmt"),
    Mutant("cknodethrow", "UndirectedConnectivity.swift", "guard blocks._graph.contains(vertex) else { throw VertexNotFound() }", "throw VertexNotFound()", mode="stmt"),
    # The condensation's generation: not recorded, and not compared.
    Mutant("condensationstamp", "StronglyConnectedComponents.swift",
           "return Condensation(components: components, graph: graph, sourceGeneration: generation)",
           "return Condensation(components: components, graph: graph, sourceGeneration: .untracked)", mode="stmt"),
    Mutant("condensationcurrent", "StronglyConnectedComponents.swift", "sourceGeneration.isCurrent(for: graph.generation)", "true"),
    # Nontrivial strong components: the self-loop noted during the search, on each numbering path
    # (stored rows, pooled rows, index-space rows, numbered rows of a graph with holes, a dictionary),
    # and which components are kept and how they are laid out.
    Mutant("ntloopnote", "NontrivialStronglyConnectedComponents.swift", "if w == vertex { loops[w] = true }", "", mode="stmt"),
    Mutant("ntloopany", "NontrivialStronglyConnectedComponents.swift", "w == vertex", "w != vertex"),
    Mutant("ntrowsloop", "NontrivialStronglyConnectedComponents.swift",
           "_LoopNotingCursor(_RowCursor(row: $0, offsets: offsets, targets: targets), vertex: $0, loops: loops)",
           "_LoopNotingCursor(_RowCursor(row: $0, offsets: offsets, targets: targets), vertex: -1, loops: loops)", nth=0),
    Mutant("ntpooledloop", "NontrivialStronglyConnectedComponents.swift",
           "_LoopNotingCursor(_PooledRowCursor(row: $0, targets: targets, targetRows: targetRows), vertex: $0, loops: loops)",
           "_LoopNotingCursor(_PooledRowCursor(row: $0, targets: targets, targetRows: targetRows), vertex: -1, loops: loops)"),
    Mutant("ntindexloop", "NontrivialStronglyConnectedComponents.swift",
           "_LoopNotingCursor(successorIndices(ofIndex: $0).makeIterator(), vertex: $0, loops: loops)",
           "_LoopNotingCursor(successorIndices(ofIndex: $0).makeIterator(), vertex: -1, loops: loops)"),
    Mutant("ntholesloop", "NontrivialStronglyConnectedComponents.swift",
           "_LoopNotingCursor(_RowCursor(row: $0, offsets: offsets, targets: targets), vertex: $0, loops: loops)",
           "_LoopNotingCursor(_RowCursor(row: $0, offsets: offsets, targets: targets), vertex: -1, loops: loops)", nth=1),
    Mutant("ntdictloop", "NontrivialStronglyConnectedComponents.swift",
           "_LoopNotingCursor(successors(of: vertices.vertices[u]).lazy.map { vertices.number(of: $0) }.makeIterator(), vertex: u, loops: loops)",
           "_LoopNotingCursor(successors(of: vertices.vertices[u]).lazy.map { vertices.number(of: $0) }.makeIterator(), vertex: -1, loops: loops)"),
    Mutant("ntkeeploops", "NontrivialStronglyConnectedComponents.swift", "        for v in 0 ..< n where loops[v] { next[labels[v]] = 0 }", "", mode="stmt"),
    Mutant("ntkeepsingle", "NontrivialStronglyConnectedComponents.swift", "size[c] > 1", "size[c] > 0"),
    Mutant("ntkeeptwo", "NontrivialStronglyConnectedComponents.swift", "size[c] > 1", "size[c] > 2"),
    Mutant("ntslot", "NontrivialStronglyConnectedComponents.swift", "                    next[labels[v]] = slot &+ 1", "", mode="stmt"),
    Mutant("ntstart", "NontrivialStronglyConnectedComponents.swift", "            start = end", "", mode="stmt"),

    # k-edge-connected components and subgraphs
    Mutant("ke_residual", "EdgeConnectedComponents.swift", "flow[rows.edges[slot]] != forward", "flow[rows.edges[slot]] == 0"),
    Mutant("ke_inside", "EdgeConnectedComponents.swift", "inside[y] == tag", "true"),
    Mutant("ke_reset", "EdgeConnectedComponents.swift", "        for e in used { flow[e] = 0 }", "", mode="stmt"),
    Mutant("ke_augment", "EdgeConnectedComponents.swift", "                flow[e] += x < y ? 1 : -1", "                flow[e] = x < y ? 1 : -1", mode="stmt"),
    Mutant("ke_cap", "EdgeConnectedComponents.swift", "maximumFlow(from: s, to: t, cap: k) >= k", "maximumFlow(from: s, to: t, cap: k) >= k - 1"),
    Mutant("ke_split", "EdgeConnectedComponents.swift", "                    if seen[v] == epoch { kept.append(v) } else { cut.append(v) }", "                    kept.append(v)", mode="stmt"),
    Mutant("ke_k2", "EdgeConnectedComponents.swift", "        if k == 2 { return biEdgeConnectedComponents() }", "        if k == 2 { return connectedComponents() }", mode="stmt"),
    Mutant("ke_one", "EdgeConnectedComponents.swift", "parts == 1", "parts <= 2"),
    Mutant("ke_relabel", "EdgeConnectedComponents.swift", "        _ = _relabelByFirstAppearance(&labels, count: count)", "", mode="stmt", nth=1),
]
