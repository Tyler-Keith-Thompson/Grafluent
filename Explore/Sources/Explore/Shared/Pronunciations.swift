import ElementaryUI

/// How to say a name from the literature: the spelling, a respelling for English speakers, the
/// IPA when it helps, and what the name is attached to.
struct Pronunciation {
    var name: String
    var say: String
    var ipa: String = ""
    var what: String
}

/// The names the pages mention whose obvious English reading is wrong, in one place so each is
/// spelled and said the same way. A name that reads as it is spelled, such as Kruskal or Yen, has none.
enum Names {
    static let dijkstra = Pronunciation(name: "Dijkstra", say: "DIKE-struh", ipa: "/ˈdɛikstra/", what: "Shortest paths when no edge is negative")
    static let boruvka = Pronunciation(name: "Borůvka", say: "BOR-oof-kah", ipa: "/ˈboruːfka/", what: "The same network, grown in parallel")
    static let erdosRenyi = Pronunciation(name: "Erdős–Rényi", say: "AIR-dersh RAY-nyee", ipa: "/ˈɛrdøːʃ ˈreːɲi/", what: "Random graphs, one coin flip per pair")
    static let barabasi = Pronunciation(name: "Barabási", say: "BAH-rah-bah-shee", ipa: "/ˈbɒrɒbaːʃi/", what: "Albert-László Barabási: random networks with hubs, built with Réka Albert")
    static let kuratowski = Pronunciation(name: "Kuratowski", say: "koo-rah-TOV-skee", ipa: "/kuraˈtɔfskʲi/", what: "Kazimierz Kuratowski: non-planar exactly when K₅ or K₃,₃ is hidden inside")
    static let wagner = Pronunciation(name: "Wagner", say: "VAHG-ner", ipa: "/ˈvaːɡnɐ/", what: "Klaus Wagner: the same test with contractions, by minors")
    static let deFraysseix = Pronunciation(name: "de Fraysseix", say: "duh fray-SEX", ipa: "/də fʁɛsɛks/", what: "Hubert de Fraysseix: the left-right planarity test, and drawing on a grid")
    static let mohri = Pronunciation(name: "Mohri", say: "moh-REE", ipa: "/moˈriː/", what: "Mehryar Mohri: one shortest-distance algorithm for every semiring")
    static let viterbi = Pronunciation(name: "Viterbi", say: "vih-TUR-bee", ipa: "/vɪˈtɜːrbi/", what: "Andrew Viterbi: the most likely path, by multiplying and keeping the best")
    static let dinic = Pronunciation(name: "Dinic", say: "DEE-nits", ipa: "/ˈdinit͡s/", what: "Yefim Dinitz: many shortest routes at once, in layers")
    static let leiden = Pronunciation(name: "Leiden", say: "LIE-den", ipa: "/ˈlɛidə(n)/", what: "Louvain with a refinement step, so every group is connected")
    static let konig = Pronunciation(name: "Kőnig", say: "KUR-nig", ipa: "/ˈkøːniɡ/", what: "In two-sided graphs, biggest matching = smallest cover")
    static let hierholzer = Pronunciation(name: "Hierholzer", say: "HEER-holt-ser", ipa: "/ˈhiːɐ̯hɔlt͡sɐ/", what: "A walk that uses every road exactly once")
    static let euler = Pronunciation(name: "Euler", say: "OY-ler", ipa: "/ˈɔɪlər/", what: "Leonhard Euler, who settled the Königsberg bridges in 1736")
    static let konigsberg = Pronunciation(name: "Königsberg", say: "KUR-nigs-bairk", ipa: "/ˈkøːnɪçsbɛʁk/", what: "The city of the seven bridges, now Kaliningrad")
    static let fleury = Pronunciation(name: "Fleury", say: "flur-EE", ipa: "/flœʁi/", what: "An older tour rule: never cross a bridge you can avoid")
    static let kosaraju = Pronunciation(name: "Kosaraju", say: "koh-suh-RAH-joo", ipa: "/koːsəˈɾaːdʒu/", what: "The same pieces in two passes, one on the reversed graph")
    static let tremaux = Pronunciation(name: "Trémaux", say: "tray-MOH", ipa: "/tʁe.mo/", what: "Depth-first search, as a rule for walking a maze")
    static let brelaz = Pronunciation(name: "Brélaz", say: "bray-LAH", ipa: "/bʁe.la/", what: "DSATUR: colour the most constrained vertex next")
    static let kleinberg = Pronunciation(name: "Kleinberg", say: "KLINE-burg", ipa: "/ˈklaɪnbɜːrɡ/", what: "Hubs and authorities, PageRank’s two-score cousin")
    static let fruchtermanReingold = Pronunciation(name: "Fruchterman–Reingold", say: "FROOK-ter-mun RINE-gold", ipa: "/ˈfruːktərmən ˈraɪnɡoʊld/", what: "Springs on the edges, repulsion between every pair")
    static let eades = Pronunciation(name: "Eades", say: "EEDZ", ipa: "/iːdz/", what: "The first spring embedder")
    static let kamadaKawai = Pronunciation(name: "Kamada–Kawai", say: "kah-MAH-dah kah-WAH-ee", what: "Springs whose rest length is the graph distance")
    static let louvain = Pronunciation(name: "Louvain", say: "loo-VAN", ipa: "/luvɛ̃/", what: "Communities by repeatedly merging what raises modularity")
    static let vizing = Pronunciation(name: "Vizing", say: "vee-ZING", ipa: "/viˈzinɡ/", what: "Vadim Vizing: every simple graph’s edges in Δ or Δ + 1 colours")
    static let nagamochiIbaraki = Pronunciation(name: "Nagamochi–Ibaraki", say: "nah-gah-MOH-chee ee-bah-RAH-kee", ipa: "/naɡamotɕi ibaɾaki/", what: "Hiroshi Nagamochi and Toshihide Ibaraki: the cheapest cut with no source or sink chosen")
    static let weisfeilerLeman = Pronunciation(name: "Weisfeiler–Leman", say: "VICE-fy-ler LAY-mun", ipa: "/ˈvaɪsfaɪlɐ ˈleːman/", what: "Boris Weisfeiler and Andrei Leman: colour refinement, a quick test that two graphs differ")
    static let adamic = Pronunciation(name: "Adamic", say: "ah-DAH-mitch", ipa: "/aˈdaːmit͡ʃ/", what: "Lada Adamic: shared friends who have few friends count for more")
    static let jaccard = Pronunciation(name: "Jaccard", say: "zha-KAR", ipa: "/ʒakaʁ/", what: "Paul Jaccard: the share of two sets that they have in common")
    static let lengauer = Pronunciation(name: "Lengauer", say: "LENG-ow-er", ipa: "/ˈlɛŋaʊ̯ɐ/", what: "Thomas Lengauer: every immediate dominator from one depth-first search, with Robert Tarjan")
    static let batageljZaversnik = Pronunciation(name: "Batagelj–Zaveršnik", say: "BAH-tah-gel zah-VEHRSH-nik", ipa: "/ˈbaːtaɡɛl zaˈʋɛːrʃnik/", what: "Vladimir Batagelj and Matjaž Zaveršnik: every core number in one pass, with buckets by degree")
    static let guan = Pronunciation(name: "Guan Meigu", say: "GWAHN may-GOO", what: "Mei-Ko Kwan, who posed the postman problem in 1960; Guan is the family name")
    static let christofides = Pronunciation(name: "Christofides", say: "kris-TOF-ih-deez", ipa: "/krɪˈstɒfɪdiːz/", what: "Nicos Christofides: a tour never more than 1.5 times the shortest, from a spanning tree and a matching")
    static let fiedler = Pronunciation(name: "Fiedler", say: "FEED-ler", ipa: "/ˈfiːdlər/", what: "Miroslav Fiedler: the second eigenvalue as a measure of connectivity, and its eigenvector as a cut")
    static let sugiyama = Pronunciation(name: "Sugiyama", say: "soo-gee-YAH-mah", ipa: "/sɯɡijama/", what: "Kozo Sugiyama: layered drawings of hierarchies, in phases, with Shojiro Tagawa and Mitsuhiko Toda")
    static let chvatal = Pronunciation(name: "Chvátal", say: "KHVAH-tahl", ipa: "/ˈxvaːtal/", what: "Václav Chvátal: the greedy set cover, and how close to the best it stays")
    static let leskovec = Pronunciation(name: "Leskovec", say: "LESS-koh-vets", ipa: "/ˈlɛskɔʋɛts/", what: "Jure Leskovec: node2vec, biased walks for learning from networks, with Aditya Grover")
    static let bronKerbosch = Pronunciation(name: "Bron–Kerbosch", say: "BRON KER-boss", ipa: "/ˈbrɔn ˈkɛrbɔs/", what: "Every maximal clique, by backtracking")
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
