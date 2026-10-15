import JavaScriptKit

// One WebAssembly module serves every page: the page names itself in `<body data-page="…">`, and
// this mounts that page's views. web/contents.txt lists the pages in reading order.
//
// Built for the build machine instead, it draws each page's first frame into the HTML: run as
// `Explore <dist> <page>…`, it fills the mount points of each `<dist>/<page>.html`.

/// Mounts the views of page `page`; false if there is no such page.
func mountPage(_ page: String) -> Bool {
    switch page {
    case "basics": BasicsPage.mount()
    case "representations": RepresentationsPage.mount()
    case "bfs": BreadthFirstPage.mount()
    case "dfs": DepthFirstPage.mount()
    case "dijkstra": DijkstraPage.mount()
    case "astar": AStarPage.mount()
    case "kpaths": KPathsPage.mount()
    case "toposort": TopologicalSortPage.mount()
    case "criticalpath": CriticalPathPage.mount()
    case "components": ComponentsPage.mount()
    case "bridges": BridgesPage.mount()
    case "euler": EulerPage.mount()
    case "giant": GiantPage.mount()
    case "huffman": HuffmanPage.mount()
    case "planarity": PlanarityPage.mount()
    case "semirings": SemiringsPage.mount()
    case "flow": FlowPage.mount()
    case "mincut": MinCutPage.mount()
    case "mincostflow": MinCostFlowPage.mount()
    case "cliques": CliquesPage.mount()
    case "isomorphism": IsomorphismPage.mount()
    case "communities": CommunitiesPage.mount()
    case "girvannewman": GirvanNewmanPage.mount()
    case "mst": MSTPage.mount()
    case "matching": MatchingPage.mount()
    case "coloring": ColoringPage.mount()
    case "edgecoloring": EdgeColoringPage.mount()
    case "pagerank": PageRankPage.mount()
    case "betweenness": BetweennessPage.mount()
    case "layout": LayoutPage.mount()
    default: return false
    }
    mountFigureSamples()
    return true
}

#if arch(wasm32)
let page = JSObject.global.document.body.getAttribute("data-page").string ?? ""
if !mountPage(page) {
    _ = JSObject.global.console.error("No explorer page is called “\(page)”.")
}
#else
writeFirstFrames(arguments: Array(CommandLine.arguments.dropFirst()))
#endif
