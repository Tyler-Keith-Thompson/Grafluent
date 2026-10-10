// `gomoryHuTree(capacity:)` (catalog §GomoryHu): Gusfield's tree with the canonical cut, NetworkX's
// tree edge for edge; the tree edge at position k joins the vertex at index k + 1 and its parent;
// for every ordered pair, `minimumCutValue(between:and:)` is the least capacity on the tree path and
// the least cut by brute force, and `minimumCut(between:and:)` is the split at the least tree edge
// nearest the first vertex, with the graph's crossing edges. Directed rows are `AdjacencyList`, or
// `DirectedPseudograph` when an edge repeats; undirected rows `UndirectedAdjacencyList`, or
// `Pseudograph` with parallel edges; each built by inserting the row's vertices, then its edges in
// order, so positions are the catalog's. In-test checks number vertices by their index in
// `vertices`. Generated from cases.md by swiftgen.py, which re-evaluates each row with ref.py's
// models; see README.md.

import AdjacencyListModule
import Flows
import GraphProtocols
import Multigraphs
import Testing

@Suite("gomoryHuTree(capacity:)")
struct GomoryHuTreeTests {
    @Test("FL-258 empty graph: nil")
    func fl258() {
        // undirected V []; E []; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(result == nil)
    }

    @Test("FL-259 one vertex: edges []")
    func fl259() throws {
        // undirected V [0]; E []; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 0)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = []
        let treeCapacities: [Int] = []
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        _ = (parent, treeCapacities, ends)
    }

    @Test("FL-260 two vertices: edges [1–0 5]")
    func fl260() throws {
        // undirected V [0, 1]; E [0–1 2, 0–1 3]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let capacities: [Int] = [2, 3]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 1)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [0]
        let treeCapacities: [Int] = [5]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-261 disconnected: zero edges join the pieces: edges [1–2 4, 2–0 0]")
    func fl261() throws {
        // undirected V [0, 1, 2]; E [1–2 4]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(1, 2)]
        let capacities: [Int] = [4]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 2)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [2, 0]
        let treeCapacities: [Int] = [4, 0]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-262 path: edges [1–0 3, 2–1 1, 3–2 2]")
    func fl262() throws {
        // undirected V [0, 1, 2, 3]; E [0–1 3, 1–2 1, 2–3 2]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let capacities: [Int] = [3, 1, 2]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 3)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [0, 1, 2]
        let treeCapacities: [Int] = [3, 1, 2]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-263 star: edges [1–0 3, 2–0 1, 3–0 2]")
    func fl263() throws {
        // undirected V [0, 1, 2, 3]; E [0–1 3, 0–2 1, 0–3 2]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let capacities: [Int] = [3, 1, 2]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 3)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [0, 0, 0]
        let treeCapacities: [Int] = [3, 1, 2]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-264 triangle: edges [1–2 3, 2–0 4]")
    func fl264() throws {
        // undirected V [0, 1, 2]; E [0–1 1, 1–2 2, 0–2 3]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
        let capacities: [Int] = [1, 2, 3]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 2)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [2, 0]
        let treeCapacities: [Int] = [3, 4]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-265 K(4), unit: edges [1–3 3, 2–3 3, 3–0 3]")
    func fl265() throws {
        // K(4); gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 3)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [3, 3, 0]
        let treeCapacities: [Int] = [3, 3, 3]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-266 cycle C(5), unit: edges [1–4 2, 2–4 2, 3–4 2, 4–0 2]")
    func fl266() throws {
        // C(5); gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let capacities: [Int] = [1, 1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 4)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [4, 4, 4, 0]
        let treeCapacities: [Int] = [2, 2, 2, 2]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-267 Wikipedia Gomory–Hu graph: edges [1–4 7, 2–0 8, 3–4 6, 4–2 6, 5–3 8]")
    func fl267() throws {
        // undirected V [0, 1, 2, 3, 4, 5]; E [0–1 1, 0–2 7, 1–2 1, 1–3 3, 1–4 2, 2–4 4, 3–4 1, 3–5 6, 4–5 2]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (1, 4), (2, 4), (3, 4), (3, 5), (4, 5)]
        let capacities: [Int] = [1, 7, 1, 3, 2, 4, 1, 6, 2]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 5)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [4, 0, 4, 2, 3]
        let treeCapacities: [Int] = [7, 8, 6, 6, 8]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-268 Stoer–Wagner paper graph: edges [2–5 7, 3–2 4, 4–3 7, 5–1 5, 6–5 6, 7–4 7, 8–7 5]")
    func fl268() throws {
        // undirected V [1, 2, 3, 4, 5, 6, 7, 8]; E [1–2 2, 1–5 3, 2–3 3, 2–5 2, 2–6 2, 3–4 4, 3–7 2, 4–7 2, 4–8 2, 5–6 3, 6–7 1, 7–8 3]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 5), (2, 3), (2, 5), (2, 6), (3, 4), (3, 7), (4, 7), (4, 8), (5, 6), (6, 7), (7, 8)]
        let capacities: [Int] = [2, 3, 3, 2, 2, 4, 2, 2, 2, 3, 1, 3]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 7)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [4, 1, 2, 0, 4, 3, 6]
        let treeCapacities: [Int] = [7, 4, 7, 5, 6, 7, 5]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-269 igraph example: triangle with a pendant: edges [1–2 2, 2–0 2, 3–2 1]")
    func fl269() throws {
        // undirected V [0, 1, 2, 3]; E [0–1 1, 1–2 1, 2–0 1, 2–3 1]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let capacities: [Int] = [1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 3)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [2, 0, 2]
        let treeCapacities: [Int] = [2, 2, 1]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-270 labels, not indices: edges [b–c 3, a–d 7, c–a 9]")
    func fl270() throws {
        // undirected V [d, b, a, c]; E [a–b 1, b–c 2, c–d 3, d–a 4, a–c 5]; gomoryHuTree(capacity:)
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "d"), ("d", "a"), ("a", "c")]
        let capacities: [Int] = [1, 2, 3, 4, 5]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "b", "a", "c"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "b", "a", "c"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 3)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [3, 0, 2]
        let treeCapacities: [Int] = [3, 7, 9]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-271 self-loop and parallel edges: edges [1–0 2, 2–1 3]")
    func fl271() throws {
        // undirected V [0, 1, 2]; E [0–0 5, 0–1 1, 1–0 1, 1–2 3]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0), (1, 2)]
        let capacities: [Int] = [5, 1, 1, 3]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 2)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [0, 1]
        let treeCapacities: [Int] = [2, 3]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-272 lcgund(9,20,10,9): edges [1–6 24, 2–6 21, 3–1 12, 4–0 16, 5–6 35, 6–4 23, 7–6 35, 8–0 12]")
    func fl272() throws {
        // lcgund(9,20,10,9); gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(5, 1), (1, 0), (7, 4), (4, 7), (7, 6), (7, 2), (5, 3), (1, 5), (1, 6), (4, 0), (6, 2), (8, 5), (5, 6), (3, 2), (5, 2), (3, 1), (6, 7), (8, 0), (4, 1), (5, 6)]
        let capacities: [Int] = [3, 2, 2, 7, 9, 8, 3, 1, 6, 9, 4, 5, 8, 2, 7, 7, 9, 7, 7, 8]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 8)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [6, 6, 1, 0, 6, 4, 6, 0]
        let treeCapacities: [Int] = [24, 21, 12, 16, 35, 23, 35, 12]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-273 Petersen, unit: edges [1–9 3, 2–9 3, 3–9 3, 4–9 3, 5–9 3, 6–9 3, 7–9 3, 8–9 3, 9–0 3]")
    func fl273() throws {
        // nx(petersen_graph); gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 9)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [9, 9, 9, 9, 9, 9, 9, 9, 0]
        let treeCapacities: [Int] = [3, 3, 3, 3, 3, 3, 3, 3, 3]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-495 UInt8, every vertex within 255: edges [1–4 111, 2–6 247, 3–0 218, 4–0 195, 5–4 40, 6–0 186, 7–0 203]")
    func fl495() throws {
        // UInt8 undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [1–5 5, 2–3 16, 4–7 21, 4–0 3, 3–7 39, 6–3 33, 6–0 43, 2–0 46, 5–0 1, 6–2 39, 2–6 119, 6–1 12, 0–7 33, 7–2 20, 0–4 66, 4–5 24, 1–3 42, 5–1 10, 7–3 40,…
        let pairs: [(Int, Int)] = [(1, 5), (2, 3), (4, 7), (4, 0), (3, 7), (6, 3), (6, 0), (2, 0), (5, 0), (6, 2), (2, 6), (6, 1), (0, 7), (7, 2), (0, 4), (4, 5), (1, 3), (5, 1), (7, 3), (1, 4), (4, 7), (4, 1), (3, 0), (3, 0), (6, 3), (3, 6), (2, 3)]
        let capacities: [UInt8] = [5, 16, 21, 3, 39, 33, 43, 46, 1, 39, 119, 12, 33, 20, 66, 24, 42, 10, 40, 22, 50, 20, 20, 12, 8, 1, 7]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 7)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [4, 6, 0, 0, 4, 0, 0]
        let treeCapacities: [UInt8] = [111, 247, 218, 195, 40, 186, 203]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-496 UInt8 star, the centre's sum past 255: edges [1–0 200, 2–0 200, 3–0 200]")
    func fl496() throws {
        // UInt8 undirected V [0, 1, 2, 3]; E [0–1 200, 0–2 200, 0–3 200]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let capacities: [UInt8] = [200, 200, 200]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 3)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [0, 0, 0]
        let treeCapacities: [UInt8] = [200, 200, 200]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }

    @Test("FL-527 Int.max path: edges [1–0 9223372036854775807, 2–1 9223372036854775807]")
    func fl527() throws {
        // undirected V [0, 1, 2]; E [0–1 9223372036854775807, 1–2 9223372036854775807]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let capacities: [Int] = [9223372036854775807, 9223372036854775807]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.gomoryHuTree { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let gomoryHu = try #require(result)
        let tree = gomoryHu.tree
        #expect(Array(tree.vertices) == vertexList)
        #expect(tree.edgeCount == 2)
        // The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut
        // value between them as its capacity.
        let parent: [Int] = [0, 1]
        let treeCapacities: [Int] = [9223372036854775807, 9223372036854775807]
        for k in 0 ..< n - 1 {
            let edge = tree.edges[k]
            #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), "tree edge \(k)")
            #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
        }
        // Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the
        // least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,
        // u on its source side, with the graph's crossing edges.
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                // The tree path, written as the child end of each tree edge from u to v.
                var upU = [u], upV = [v]
                while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }
                while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }
                let lca = upU.first { upV.contains($0) }!
                let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())
                let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!
                let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!
                let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])
                #expect(minimum == least, "\(vertexList[u]), \(vertexList[v])")
                // The subtree below the least edge, and u's side of the split.
                let below = (0 ..< n).map { x in
                    var y = x
                    while y != 0 && y != firstLeast { y = parent[y - 1] }
                    return y == firstLeast
                }
                let inS = (0 ..< n).map { below[$0] == below[u] }
                let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])
                #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, "\(vertexList[u]), \(vertexList[v])")
                let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }
                #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\($0)" : "\($0)r" })
                #expect(cut.value == least, "\(vertexList[u]), \(vertexList[v])")
                #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)
                // Brute force: the least cut separating u from v.
                var best: Int128? = nil
                for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                    var value: Int128 = 0
                    for k in pairs.indices where ends[k].0 != ends[k].1 {
                        if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += Int128(capacities[k]) }
                    }
                    if best == nil || value < best! { best = value }
                }
                #expect(best == Int128(least), "\(vertexList[u]), \(vertexList[v])")
            }
        }
    }
}
