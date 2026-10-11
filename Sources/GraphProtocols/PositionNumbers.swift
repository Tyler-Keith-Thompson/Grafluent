/// The page size of paged position storage: `StableDirectedGraph`'s vertex and edge pages, its
/// `VertexMap` and `EdgeMap`, and `_PositionNumbers` all split positions into pages of
/// `1 << shift` slots, so a page index is `position >> shift` and a slot in it `position & mask`.
@frozen
@usableFromInline
package enum _PositionPage {
    @inlinable package static var shift: Int { 10 }
    @inlinable package static var size: Int { 1 << shift }
    @inlinable package static var mask: Int { size &- 1 }
}

/// A map from positions (vertex or edge positions of a `SparselyIndexedDirectedGraph`) to
/// numbers, paged so that its memory is O(numbered pages + page span) instead of O(highest
/// position): a page table from `firstPage` on, each entry the offset of that page's block in
/// `numbers` or -1, and one block of `_PositionPage.size` numbers per page holding at least one
/// numbered position (-1 at the others). A lookup is two array reads.
@frozen
public struct _PositionNumbers: Sendable {
    /// The page number of `pageOffsets[0]`.
    @usableFromInline package let firstPage: Int
    /// Each page's block offset in `numbers`, or -1 for a page with no numbered position.
    @usableFromInline package let pageOffsets: [Int]
    /// The blocks, `_PositionPage.size` numbers each; -1 at a position without a number.
    @usableFromInline package let numbers: [Int]

    @inlinable
    package init(firstPage: Int, pageOffsets: [Int], numbers: [Int]) {
        self.firstPage = firstPage
        self.pageOffsets = pageOffsets
        self.numbers = numbers
    }

    /// No position numbered.
    @inlinable
    package init() {
        self.init(firstPage: 0, pageOffsets: [], numbers: [])
    }

    /// The number at `position`, or -1 when it has none; never traps.
    @inlinable
    package subscript(position: Int) -> Int {
        guard position >= 0 else { return -1 }
        let k = (position &>> _PositionPage.shift) &- firstPage
        guard k >= 0, k < pageOffsets.count else { return -1 }
        let offset = pageOffsets[k]
        return offset < 0 ? -1 : numbers[offset &+ (position & _PositionPage.mask)]
    }

    /// Builds a `_PositionNumbers` from positions given in increasing order. O(1) amortized per
    /// position plus O(`_PositionPage.size`) per page first touched.
    @frozen
    @usableFromInline
    package struct Builder {
        @usableFromInline var firstPage: Int
        @usableFromInline var pageOffsets: [Int]
        @usableFromInline var numbers: [Int]

        @inlinable
        package init() {
            firstPage = -1
            pageOffsets = []
            numbers = []
        }

        /// Numbers `position`, which must exceed every position appended before.
        @inlinable
        package mutating func append(_ position: Int, number: Int) {
            precondition(position >= 0, "Negative position")
            let page = position &>> _PositionPage.shift
            if firstPage < 0 { firstPage = page }
            let k = page &- firstPage
            precondition(k >= pageOffsets.count - 1, "Positions must increase")
            if k >= pageOffsets.count {
                if k > pageOffsets.count { pageOffsets.append(contentsOf: repeatElement(-1, count: k &- pageOffsets.count)) }
                pageOffsets.append(numbers.count)
                numbers.append(contentsOf: repeatElement(-1, count: _PositionPage.size))
            }
            numbers[pageOffsets[k] &+ (position & _PositionPage.mask)] = number
        }

        @inlinable
        package func build() -> _PositionNumbers {
            _PositionNumbers(firstPage: Swift.max(firstPage, 0), pageOffsets: pageOffsets, numbers: numbers)
        }
    }
}
