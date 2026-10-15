import JavaScriptKit

// One WebAssembly module serves every page: the page names itself in `<body data-page="…">`, and
// this mounts that page's views. web/contents.txt lists the pages in reading order.
let page = JSObject.global.document.body.getAttribute("data-page").string ?? ""
switch page {
case "basics": BasicsPage.mount()
case "representations": RepresentationsPage.mount()
case "bfs": BreadthFirstPage.mount()
case "dfs": DepthFirstPage.mount()
case "dijkstra": DijkstraPage.mount()
case "astar": AStarPage.mount()
case "toposort": TopologicalSortPage.mount()
case "components": ComponentsPage.mount()
case "matching": MatchingPage.mount()
case "coloring": ColoringPage.mount()
case "pagerank": PageRankPage.mount()
case "layout": LayoutPage.mount()
default: _ = JSObject.global.console.error("No explorer page is called “\(page)”.")
}
mountFigureSamples()
