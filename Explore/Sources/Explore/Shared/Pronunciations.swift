import ElementaryUI

/// How to say a name from the literature: the spelling, a respelling for English speakers, the
/// IPA when it helps, and what the name is attached to.
struct Pronunciation {
    var name: String
    var say: String
    var ipa: String = ""
    var what: String
}

/// Every name the pages mention, in one place so each is spelled and said the same way.
enum Names {
    static let dijkstra = Pronunciation(name: "Dijkstra", say: "DIKE-struh", ipa: "/ˈdɛikstra/", what: "Shortest paths when no edge is negative")
    static let bellmanFord = Pronunciation(name: "Bellman–Ford", say: "BELL-mun FORD", what: "Shortest paths that allow negative edges")
    static let kruskal = Pronunciation(name: "Kruskal", say: "KRUSS-kul", ipa: "/ˈkrʌskəl/", what: "Cheapest network that connects everything")
    static let prim = Pronunciation(name: "Prim", say: "PRIM", ipa: "/prɪm/", what: "The same network, grown from one place")
    static let boruvka = Pronunciation(name: "Borůvka", say: "BOR-oof-kah", ipa: "/ˈboruːfka/", what: "The same network, grown in parallel")
    static let hart = Pronunciation(name: "A*", say: "A-star", what: "Dijkstra with a sense of direction")
    static let erdosRenyi = Pronunciation(name: "Erdős–Rényi", say: "AIR-dersh RAY-nyee", ipa: "/ˈɛrdøːʃ ˈreːɲi/", what: "Random graphs, one coin flip per pair")
    static let konig = Pronunciation(name: "Kőnig", say: "KUR-nig", ipa: "/ˈkøːniɡ/", what: "In two-sided graphs, biggest matching = smallest cover")
    static let hierholzer = Pronunciation(name: "Hierholzer", say: "HEER-holt-ser", ipa: "/ˈhiːɐ̯hɔlt͡sɐ/", what: "A walk that uses every road exactly once")
    static let tarjan = Pronunciation(name: "Tarjan", say: "TAR-jun", ipa: "/ˈtɑːrdʒən/", what: "Strongly connected pieces in one depth-first pass")
    static let kosaraju = Pronunciation(name: "Kosaraju", say: "koh-suh-RAH-joo", ipa: "/koːsəˈɾaːdʒu/", what: "The same pieces in two passes, one on the reversed graph")
    static let pearce = Pronunciation(name: "Pearce", say: "PEERSS", ipa: "/pɪərs/", what: "Tarjan’s algorithm in less memory")
    static let moore = Pronunciation(name: "Moore", say: "MOOR", ipa: "/mʊər/", what: "Breadth-first search, for the shortest way out of a maze")
    static let tremaux = Pronunciation(name: "Trémaux", say: "tray-MOH", ipa: "/tʁe.mo/", what: "Depth-first search, as a rule for walking a maze")
    static let hopcroft = Pronunciation(name: "Hopcroft", say: "HOP-kroft", ipa: "/ˈhɒpkrɒft/", what: "With Tarjan, depth-first search as a tool for graph algorithms")
    static let kahn = Pronunciation(name: "Kahn", say: "KAHN", ipa: "/kɑːn/", what: "Topological order by peeling off steps with nothing left to wait for")
    static let hopcroftKarp = Pronunciation(name: "Hopcroft–Karp", say: "HOP-kroft KARP", ipa: "/ˈhɒpkrɒft ˈkɑːrp/", what: "Maximum matching in a two-sided graph, many augmenting paths per round")
    static let edmonds = Pronunciation(name: "Edmonds", say: "ED-mundz", ipa: "/ˈɛdməndz/", what: "Maximum matching in any graph, by shrinking odd cycles (blossoms)")
    static let hall = Pronunciation(name: "Hall", say: "HAWL", ipa: "/hɔːl/", what: "When everyone on one side can be matched")
    static let kuhn = Pronunciation(name: "Kuhn", say: "KOON", ipa: "/kuːn/", what: "The Hungarian method for the cheapest assignment")
    static let welshPowell = Pronunciation(name: "Welsh–Powell", say: "WELSH POW-ul", what: "Greedy colouring, busiest vertex first")
    static let brelaz = Pronunciation(name: "Brélaz", say: "bray-LAH", ipa: "/bʁe.la/", what: "DSATUR: colour the most constrained vertex next")
    static let brooks = Pronunciation(name: "Brooks", say: "BROOKS", ipa: "/brʊks/", what: "Never more colours than the largest degree, with two exceptions")
    static let page = Pronunciation(name: "Page", say: "PAYJ", ipa: "/peɪdʒ/", what: "Larry Page, the Page in PageRank")
    static let brin = Pronunciation(name: "Brin", say: "BRIN", ipa: "/brɪn/", what: "Sergey Brin, PageRank’s co-author")
    static let markov = Pronunciation(name: "Markov", say: "MAR-koff", ipa: "/ˈmarkəf/", what: "Chains of random steps; PageRank is one’s long-run average")
    static let kleinberg = Pronunciation(name: "Kleinberg", say: "KLINE-burg", ipa: "/ˈklaɪnbɜːrɡ/", what: "Hubs and authorities, PageRank’s two-score cousin")
    static let fruchtermanReingold = Pronunciation(name: "Fruchterman–Reingold", say: "FROOK-ter-mun RINE-gold", ipa: "/ˈfruːktərmən ˈraɪnɡoʊld/", what: "Springs on the edges, repulsion between every pair")
    static let eades = Pronunciation(name: "Eades", say: "EEDZ", ipa: "/iːdz/", what: "The first spring embedder")
    static let barnesHut = Pronunciation(name: "Barnes–Hut", say: "BARNZ HUT", ipa: "/ˈbɑːrnz ˈhʌt/", what: "Far-away vertices pushed as one lump, for speed")
    static let kamadaKawai = Pronunciation(name: "Kamada–Kawai", say: "kah-MAH-dah kah-WAH-ee", what: "Springs whose rest length is the graph distance")
    static let forceAtlas = Pronunciation(name: "ForceAtlas2", say: "FORSS AT-lus TOO", what: "Gephi’s layout, tuned to show clusters")
    static let louvain = Pronunciation(name: "Louvain", say: "loo-VAN", ipa: "/luvɛ̃/", what: "Communities by repeatedly merging what raises modularity")
    static let bronKerbosch = Pronunciation(name: "Bron–Kerbosch", say: "BRON KER-boss", ipa: "/ˈbrɔn ˈkɛrbɔs/", what: "Every maximal clique, by backtracking")
    static let fordFulkerson = Pronunciation(name: "Ford–Fulkerson", say: "FORD FULL-ker-sun", what: "Maximum flow by pushing along augmenting paths")
}

/// The names a page mentions, each with how to say it.
@View
struct NamesStrip {
    var names: [Pronunciation]

    var body: some View {
        div(.class("names")) {
            for name in names {
                div(.class("name")) {
                    b { name.name }
                    span(.class("how")) { name.say }
                    if !name.ipa.isEmpty {
                        span(.class("ipa")) { name.ipa }
                    }
                    span(.class("what")) { name.what }
                }
            }
        }
    }
}
