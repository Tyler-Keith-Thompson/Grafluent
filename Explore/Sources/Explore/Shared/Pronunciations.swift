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
    static let kruskal = Pronunciation(name: "Kruskal", say: "KRUSS-kul", ipa: "/ˈkrʌskəl/", what: "Cheapest network that connects everything")
    static let boruvka = Pronunciation(name: "Borůvka", say: "BOR-oof-kah", ipa: "/ˈboruːfka/", what: "The same network, grown in parallel")
    static let erdosRenyi = Pronunciation(name: "Erdős–Rényi", say: "AIR-dersh RAY-nyee", ipa: "/ˈɛrdøːʃ ˈreːɲi/", what: "Random graphs, one coin flip per pair")
    static let barabasiAlbert = Pronunciation(name: "Barabási–Albert", say: "BAR-uh-bah-shee AL-burt", ipa: "/ˈbɒrɒbaːʃi ˈælbərt/", what: "Random networks with hubs: the rich get richer")
    static let wattsStrogatz = Pronunciation(name: "Watts–Strogatz", say: "WOTS STROH-gats", ipa: "/ˈwɒts ˈstroʊɡæts/", what: "Small worlds: a ring of neighbours with a few long links")
    static let kuratowski = Pronunciation(name: "Kuratowski", say: "koo-rah-TOV-skee", ipa: "/kuraˈtɔfskʲi/", what: "Kazimierz Kuratowski: non-planar exactly when K₅ or K₃,₃ is hidden inside")
    static let wagner = Pronunciation(name: "Wagner", say: "VAHG-ner", ipa: "/ˈvaːɡnɐ/", what: "Klaus Wagner: the same test with contractions, by minors")
    static let deFraysseix = Pronunciation(name: "de Fraysseix", say: "duh fray-SEX", ipa: "/də fʁɛsɛks/", what: "Hubert de Fraysseix: the left-right planarity test, and drawing on a grid")
    static let mohri = Pronunciation(name: "Mohri", say: "moh-REE", ipa: "/moˈriː/", what: "Mehryar Mohri: one shortest-distance algorithm for every semiring")
    static let viterbi = Pronunciation(name: "Viterbi", say: "vih-TUR-bee", ipa: "/vɪˈtɜːrbi/", what: "Andrew Viterbi: the most likely path, by multiplying and keeping the best")
    static let dinic = Pronunciation(name: "Dinic", say: "DEE-nits", ipa: "/ˈdinit͡s/", what: "Yefim Dinitz: many shortest routes at once, in layers")
    static let tomita = Pronunciation(name: "Tomita", say: "toh-MEE-tah", ipa: "/tomita/", what: "Etsuji Tomita: the pivot that keeps the search near its best case")
    static let leiden = Pronunciation(name: "Leiden", say: "LIE-den", ipa: "/ˈlɛidə(n)/", what: "Louvain with a refinement step, so every group is connected")
    static let blondel = Pronunciation(name: "Blondel", say: "blon-DEL", ipa: "/blɔ̃dɛl/", what: "Vincent Blondel, first author of the Louvain method")
    static let konig = Pronunciation(name: "Kőnig", say: "KUR-nig", ipa: "/ˈkøːniɡ/", what: "In two-sided graphs, biggest matching = smallest cover")
    static let hierholzer = Pronunciation(name: "Hierholzer", say: "HEER-holt-ser", ipa: "/ˈhiːɐ̯hɔlt͡sɐ/", what: "A walk that uses every road exactly once")
    static let euler = Pronunciation(name: "Euler", say: "OY-ler", ipa: "/ˈɔɪlər/", what: "Leonhard Euler, who settled the Königsberg bridges in 1736")
    static let konigsberg = Pronunciation(name: "Königsberg", say: "KUR-nigs-bairk", ipa: "/ˈkøːnɪçsbɛʁk/", what: "The city of the seven bridges, now Kaliningrad")
    static let fleury = Pronunciation(name: "Fleury", say: "flur-EE", ipa: "/flœʁi/", what: "An older tour rule: never cross a bridge you can avoid")
    static let tarjan = Pronunciation(name: "Tarjan", say: "TAR-jun", ipa: "/ˈtɑːrdʒən/", what: "Strongly connected pieces in one depth-first pass")
    static let kosaraju = Pronunciation(name: "Kosaraju", say: "koh-suh-RAH-joo", ipa: "/koːsəˈɾaːdʒu/", what: "The same pieces in two passes, one on the reversed graph")
    static let tremaux = Pronunciation(name: "Trémaux", say: "tray-MOH", ipa: "/tʁe.mo/", what: "Depth-first search, as a rule for walking a maze")
    static let kuhn = Pronunciation(name: "Kuhn", say: "KOON", ipa: "/kuːn/", what: "The Hungarian method for the cheapest assignment")
    static let brelaz = Pronunciation(name: "Brélaz", say: "bray-LAH", ipa: "/bʁe.la/", what: "DSATUR: colour the most constrained vertex next")
    static let kleinberg = Pronunciation(name: "Kleinberg", say: "KLINE-burg", ipa: "/ˈklaɪnbɜːrɡ/", what: "Hubs and authorities, PageRank’s two-score cousin")
    static let fruchtermanReingold = Pronunciation(name: "Fruchterman–Reingold", say: "FROOK-ter-mun RINE-gold", ipa: "/ˈfruːktərmən ˈraɪnɡoʊld/", what: "Springs on the edges, repulsion between every pair")
    static let eades = Pronunciation(name: "Eades", say: "EEDZ", ipa: "/iːdz/", what: "The first spring embedder")
    static let kamadaKawai = Pronunciation(name: "Kamada–Kawai", say: "kah-MAH-dah kah-WAH-ee", what: "Springs whose rest length is the graph distance")
    static let louvain = Pronunciation(name: "Louvain", say: "loo-VAN", ipa: "/luvɛ̃/", what: "Communities by repeatedly merging what raises modularity")
    static let bronKerbosch = Pronunciation(name: "Bron–Kerbosch", say: "BRON KER-bosh", ipa: "/ˈbrɔn ˈkɛrbɔs/", what: "Every maximal clique, by backtracking")
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
