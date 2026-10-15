// snippet: cyclefinding-imports
import FunctionalGraphs
import GraphProtocols
// snippet end

// The reading list of the cycle finding page and the two searches it runs. The marked regions are
// its code panel.

// snippet: cyclefinding-pages
// Pages A, B, C, … are 0, 1, 2, …; page i’s “Next” link opens page nextPage[i].
let nextPage = [1, 2, 3, 4, 5, 6, 7, 8, 4, 2, 9, 6]
let readingList = FunctionalGraph(successors: nextPage)
// snippet end

/// Every event of Floyd's and of Brent's cycle detection from page 0.
func cycleSearches() -> (floyd: [FloydCycleDetectionEvent], brent: [BrentCycleDetectionEvent]) {
    // snippet: cyclefinding-floyd
    let floyd = Array(readingList.lazy.floydCycleDetection(from: 0))   // →
    // snippet end
    // snippet: cyclefinding-brent
    let brent = Array(readingList.lazy.brentCycleDetection(from: 0))   // →
    // snippet end
    return (floyd, brent)
}
