// `linearSumAssignment(rowCount:columnCount:maximize:cost:)` (catalog §Assignment, MA-182 – MA-212):
// scipy 1.18.1's `(row_ind, col_ind)` exactly, and the cost; validity (pairs by ascending row, no
// row or column twice, no forbidden pair, the cost the sum) and the optimum by brute force over
// every assignment. `nil` entries are forbidden pairs (scipy's +inf). MA-212 is exact in `Int` where
// scipy's float64 rounds. Generated from cases.md by swiftgen.py, which re-evaluates each row with
// ref.py's model; see README.md.

import MatchingModule
import Testing

@Suite("linearSumAssignment: scipy's shortest augmenting path")
struct LinearSumAssignmentTests {
    @Test("MA-182 scipy square: rows [0, 1, 2]; columns [1, 0, 2]; cost 850")
    func ma182() throws {
        // [400 150 400; 400 450 600; 300 225 300]; linearSumAssignment(rowCount: 3, columnCount: 3)
        let matrix: [[Int?]] = [[400, 150, 400], [400, 450, 600], [300, 225, 300]]
        let assignment = try #require(linearSumAssignment(rowCount: 3, columnCount: 3) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2])
        #expect(assignment.columns == [1, 0, 2])
        #expect(assignment.cost == 850)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 3 && assignment.columns.count == 3)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (3, 3)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-183 scipy rectangular: rows [0, 1, 2]; columns [1, 3, 2]; cost 452")
    func ma183() throws {
        // [400 150 400 1; 400 450 600 2; 300 225 300 3]; linearSumAssignment(rowCount: 3, columnCount: 4)
        let matrix: [[Int?]] = [[400, 150, 400, 1], [400, 450, 600, 2], [300, 225, 300, 3]]
        let assignment = try #require(linearSumAssignment(rowCount: 3, columnCount: 4) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2])
        #expect(assignment.columns == [1, 3, 2])
        #expect(assignment.cost == 452)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 3 && assignment.columns.count == 3)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (3, 4)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-184 scipy square 2: rows [0, 1, 2]; columns [0, 2, 1]; cost 18")
    func ma184() throws {
        // [10 10 8; 9 8 1; 9 7 4]; linearSumAssignment(rowCount: 3, columnCount: 3)
        let matrix: [[Int?]] = [[10, 10, 8], [9, 8, 1], [9, 7, 4]]
        let assignment = try #require(linearSumAssignment(rowCount: 3, columnCount: 3) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2])
        #expect(assignment.columns == [0, 2, 1])
        #expect(assignment.cost == 18)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 3 && assignment.columns.count == 3)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (3, 3)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-185 scipy rectangular 2: rows [0, 1, 2]; columns [1, 3, 2]; cost 15")
    func ma185() throws {
        // [10 10 8 11; 9 8 1 1; 9 7 4 10]; linearSumAssignment(rowCount: 3, columnCount: 4)
        let matrix: [[Int?]] = [[10, 10, 8, 11], [9, 8, 1, 1], [9, 7, 4, 10]]
        let assignment = try #require(linearSumAssignment(rowCount: 3, columnCount: 4) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2])
        #expect(assignment.columns == [1, 3, 2])
        #expect(assignment.cost == 15)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 3 && assignment.columns.count == 3)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (3, 4)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-186 scipy with forbidden entries: rows [0, 1, 2]; columns [0, 2, 1]; cost 18")
    func ma186() throws {
        // [10 ∞ ∞; ∞ ∞ 1; ∞ 7 ∞]; linearSumAssignment(rowCount: 3, columnCount: 3)
        let matrix: [[Int?]] = [[10, nil, nil], [nil, nil, 1], [nil, 7, nil]]
        let assignment = try #require(linearSumAssignment(rowCount: 3, columnCount: 3) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2])
        #expect(assignment.columns == [0, 2, 1])
        #expect(assignment.cost == 18)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 3 && assignment.columns.count == 3)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (3, 3)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-187 scipy square, maximize: rows [0, 1, 2]; columns [0, 2, 1]; cost 1225")
    func ma187() throws {
        // [400 150 400; 400 450 600; 300 225 300]; linearSumAssignment(rowCount: 3, columnCount: 3, maximize: true)
        let matrix: [[Int?]] = [[400, 150, 400], [400, 450, 600], [300, 225, 300]]
        let assignment = try #require(linearSumAssignment(rowCount: 3, columnCount: 3, maximize: true) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2])
        #expect(assignment.columns == [0, 2, 1])
        #expect(assignment.cost == 1225)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 3 && assignment.columns.count == 3)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (3, 3)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total > best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-188 scipy rectangular, maximize: rows [0, 1, 2]; columns [0, 2, 1]; cost 1225")
    func ma188() throws {
        // [400 150 400 1; 400 450 600 2; 300 225 300 3]; linearSumAssignment(rowCount: 3, columnCount: 4, maximize: true)
        let matrix: [[Int?]] = [[400, 150, 400, 1], [400, 450, 600, 2], [300, 225, 300, 3]]
        let assignment = try #require(linearSumAssignment(rowCount: 3, columnCount: 4, maximize: true) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2])
        #expect(assignment.columns == [0, 2, 1])
        #expect(assignment.cost == 1225)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 3 && assignment.columns.count == 3)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (3, 4)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total > best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-189 tall matrix (transposed internally): rows [2, 3]; columns [0, 1]; cost 1")
    func ma189() throws {
        // [1 2; 3 4; 0 9; 5 1]; linearSumAssignment(rowCount: 4, columnCount: 2)
        let matrix: [[Int?]] = [[1, 2], [3, 4], [0, 9], [5, 1]]
        let assignment = try #require(linearSumAssignment(rowCount: 4, columnCount: 2) { matrix[$0][$1] })
        #expect(assignment.rows == [2, 3])
        #expect(assignment.columns == [0, 1])
        #expect(assignment.cost == 1)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 2 && assignment.columns.count == 2)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[b][a] }
        let (shorter, longer) = (2, 4)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-190 tall matrix, maximize: rows [2, 3]; columns [1, 0]; cost 14")
    func ma190() throws {
        // [1 2; 3 4; 0 9; 5 1]; linearSumAssignment(rowCount: 4, columnCount: 2, maximize: true)
        let matrix: [[Int?]] = [[1, 2], [3, 4], [0, 9], [5, 1]]
        let assignment = try #require(linearSumAssignment(rowCount: 4, columnCount: 2, maximize: true) { matrix[$0][$1] })
        #expect(assignment.rows == [2, 3])
        #expect(assignment.columns == [1, 0])
        #expect(assignment.cost == 14)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 2 && assignment.columns.count == 2)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[b][a] }
        let (shorter, longer) = (2, 4)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total > best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-191 0×0: rows []; columns []; cost 0")
    func ma191() throws {
        // [] (0×0); linearSumAssignment(rowCount: 0, columnCount: 0)
        let matrix: [[Int?]] = []
        let assignment = try #require(linearSumAssignment(rowCount: 0, columnCount: 0) { matrix[$0][$1] })
        #expect(assignment.rows == [])
        #expect(assignment.columns == [])
        #expect(assignment.cost == 0)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 0 && assignment.columns.count == 0)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
    }

    @Test("MA-192 2×0: rows []; columns []; cost 0")
    func ma192() throws {
        // [] (2×0); linearSumAssignment(rowCount: 2, columnCount: 0)
        let matrix: [[Int?]] = [[], []]
        let assignment = try #require(linearSumAssignment(rowCount: 2, columnCount: 0) { matrix[$0][$1] })
        #expect(assignment.rows == [])
        #expect(assignment.columns == [])
        #expect(assignment.cost == 0)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 0 && assignment.columns.count == 0)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
    }

    @Test("MA-193 1×1: rows [0]; columns [0]; cost 7")
    func ma193() throws {
        // [7]; linearSumAssignment(rowCount: 1, columnCount: 1)
        let matrix: [[Int?]] = [[7]]
        let assignment = try #require(linearSumAssignment(rowCount: 1, columnCount: 1) { matrix[$0][$1] })
        #expect(assignment.rows == [0])
        #expect(assignment.columns == [0])
        #expect(assignment.cost == 7)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 1 && assignment.columns.count == 1)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (1, 1)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-194 1×3 picks the least: rows [0]; columns [1]; cost 1")
    func ma194() throws {
        // [3 1 2]; linearSumAssignment(rowCount: 1, columnCount: 3)
        let matrix: [[Int?]] = [[3, 1, 2]]
        let assignment = try #require(linearSumAssignment(rowCount: 1, columnCount: 3) { matrix[$0][$1] })
        #expect(assignment.rows == [0])
        #expect(assignment.columns == [1])
        #expect(assignment.cost == 1)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 1 && assignment.columns.count == 1)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (1, 3)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-195 3×1 picks the least: rows [1]; columns [0]; cost 1")
    func ma195() throws {
        // [3; 1; 2]; linearSumAssignment(rowCount: 3, columnCount: 1)
        let matrix: [[Int?]] = [[3], [1], [2]]
        let assignment = try #require(linearSumAssignment(rowCount: 3, columnCount: 1) { matrix[$0][$1] })
        #expect(assignment.rows == [1])
        #expect(assignment.columns == [0])
        #expect(assignment.cost == 1)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 1 && assignment.columns.count == 1)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[b][a] }
        let (shorter, longer) = (1, 3)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-196 constant 3×3: identity (reversed column scan): rows [0, 1, 2]; columns [0, 1, 2]; cost 15")
    func ma196() throws {
        // [5 5 5; 5 5 5; 5 5 5]; linearSumAssignment(rowCount: 3, columnCount: 3)
        let matrix: [[Int?]] = [[5, 5, 5], [5, 5, 5], [5, 5, 5]]
        let assignment = try #require(linearSumAssignment(rowCount: 3, columnCount: 3) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2])
        #expect(assignment.columns == [0, 1, 2])
        #expect(assignment.cost == 15)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 3 && assignment.columns.count == 3)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (3, 3)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-197 zeros 3×4: rows [0, 1, 2]; columns [0, 1, 2]; cost 0")
    func ma197() throws {
        // [0 0 0 0; 0 0 0 0; 0 0 0 0]; linearSumAssignment(rowCount: 3, columnCount: 4)
        let matrix: [[Int?]] = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
        let assignment = try #require(linearSumAssignment(rowCount: 3, columnCount: 4) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2])
        #expect(assignment.columns == [0, 1, 2])
        #expect(assignment.cost == 0)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 3 && assignment.columns.count == 3)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (3, 4)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-198 zeros 4×3: rows [0, 1, 2]; columns [0, 1, 2]; cost 0")
    func ma198() throws {
        // [0 0 0; 0 0 0; 0 0 0; 0 0 0]; linearSumAssignment(rowCount: 4, columnCount: 3)
        let matrix: [[Int?]] = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]]
        let assignment = try #require(linearSumAssignment(rowCount: 4, columnCount: 3) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2])
        #expect(assignment.columns == [0, 1, 2])
        #expect(assignment.cost == 0)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 3 && assignment.columns.count == 3)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[b][a] }
        let (shorter, longer) = (3, 4)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-199 negative costs: rows [0, 1]; columns [1, 0]; cost -8")
    func ma199() throws {
        // [-1 -5; -3 -2]; linearSumAssignment(rowCount: 2, columnCount: 2)
        let matrix: [[Int?]] = [[-1, -5], [-3, -2]]
        let assignment = try #require(linearSumAssignment(rowCount: 2, columnCount: 2) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1])
        #expect(assignment.columns == [1, 0])
        #expect(assignment.cost == -8)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 2 && assignment.columns.count == 2)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (2, 2)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-200 mixed signs, maximize: rows [0, 1, 2]; columns [1, 0, 2]; cost 11")
    func ma200() throws {
        // [-1 4 0; 2 -3 1; 0 0 5]; linearSumAssignment(rowCount: 3, columnCount: 3, maximize: true)
        let matrix: [[Int?]] = [[-1, 4, 0], [2, -3, 1], [0, 0, 5]]
        let assignment = try #require(linearSumAssignment(rowCount: 3, columnCount: 3, maximize: true) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2])
        #expect(assignment.columns == [1, 0, 2])
        #expect(assignment.cost == 11)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 3 && assignment.columns.count == 3)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (3, 3)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total > best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-201 floats: rows [0, 1]; columns [0, 1]; cost 1.25")
    func ma201() throws {
        // [0.5 1.25; 1.0 0.75]; linearSumAssignment(rowCount: 2, columnCount: 2)
        let matrix: [[Double?]] = [[0.5, 1.25], [1.0, 0.75]]
        let assignment = try #require(linearSumAssignment(rowCount: 2, columnCount: 2) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1])
        #expect(assignment.columns == [0, 1])
        #expect(assignment.cost == 1.25)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 2 && assignment.columns.count == 2)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Double = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Double? { matrix[a][b] }
        let (shorter, longer) = (2, 2)
        var taken = [Bool](repeating: false, count: longer)
        var best: Double?
        func place(_ a: Int, _ total: Double) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(abs(assignment.cost - best!) <= 1e-9 * max(1, abs(best!)), "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-202 infeasible: a row all forbidden: nil (infeasible)")
    func ma202() {
        // [1 2 ∞; ∞ ∞ ∞]; linearSumAssignment(rowCount: 2, columnCount: 3)
        let matrix: [[Int?]] = [[1, 2, nil], [nil, nil, nil]]
        #expect(linearSumAssignment(rowCount: 2, columnCount: 3) { matrix[$0][$1] } == nil)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (2, 3)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(best == nil, "no assignment avoids the forbidden pairs, by brute force")
    }

    @Test("MA-203 infeasible: two rows need one column: nil (infeasible)")
    func ma203() {
        // [1 ∞; 2 ∞]; linearSumAssignment(rowCount: 2, columnCount: 2)
        let matrix: [[Int?]] = [[1, nil], [2, nil]]
        #expect(linearSumAssignment(rowCount: 2, columnCount: 2) { matrix[$0][$1] } == nil)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (2, 2)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(best == nil, "no assignment avoids the forbidden pairs, by brute force")
    }

    @Test("MA-204 feasible only one way: rows [0, 1, 2]; columns [0, 2, 1]; cost 7")
    func ma204() throws {
        // [1 ∞ ∞; ∞ ∞ 2; 3 4 ∞]; linearSumAssignment(rowCount: 3, columnCount: 3)
        let matrix: [[Int?]] = [[1, nil, nil], [nil, nil, 2], [3, 4, nil]]
        let assignment = try #require(linearSumAssignment(rowCount: 3, columnCount: 3) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2])
        #expect(assignment.columns == [0, 2, 1])
        #expect(assignment.cost == 7)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 3 && assignment.columns.count == 3)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (3, 3)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-205 rectangular with a forbidden column: rows [0, 1]; columns [0, 2]; cost 2")
    func ma205() throws {
        // [1 ∞ 3; 2 ∞ 1]; linearSumAssignment(rowCount: 2, columnCount: 3)
        let matrix: [[Int?]] = [[1, nil, 3], [2, nil, 1]]
        let assignment = try #require(linearSumAssignment(rowCount: 2, columnCount: 3) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1])
        #expect(assignment.columns == [0, 2])
        #expect(assignment.cost == 2)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 2 && assignment.columns.count == 2)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (2, 3)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-206 ties: anti-diagonal equal: rows [0, 1]; columns [1, 0]; cost 0")
    func ma206() throws {
        // [1 0; 0 1]; linearSumAssignment(rowCount: 2, columnCount: 2)
        let matrix: [[Int?]] = [[1, 0], [0, 1]]
        let assignment = try #require(linearSumAssignment(rowCount: 2, columnCount: 2) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1])
        #expect(assignment.columns == [1, 0])
        #expect(assignment.cost == 0)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 2 && assignment.columns.count == 2)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (2, 2)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-207 ties: two optima: rows [0, 1]; columns [0, 1]; cost 4")
    func ma207() throws {
        // [1 2; 2 3]; linearSumAssignment(rowCount: 2, columnCount: 2)
        let matrix: [[Int?]] = [[1, 2], [2, 3]]
        let assignment = try #require(linearSumAssignment(rowCount: 2, columnCount: 2) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1])
        #expect(assignment.columns == [0, 1])
        #expect(assignment.cost == 4)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 2 && assignment.columns.count == 2)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (2, 2)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-208 ties: Latin square 3×3: rows [0, 1, 2]; columns [0, 2, 1]; cost 0")
    func ma208() throws {
        // [0 1 2; 1 2 0; 2 0 1]; linearSumAssignment(rowCount: 3, columnCount: 3)
        let matrix: [[Int?]] = [[0, 1, 2], [1, 2, 0], [2, 0, 1]]
        let assignment = try #require(linearSumAssignment(rowCount: 3, columnCount: 3) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2])
        #expect(assignment.columns == [0, 2, 1])
        #expect(assignment.cost == 0)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 3 && assignment.columns.count == 3)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (3, 3)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-209 permutation matrix costs: rows [0, 1, 2, 3]; columns [2, 0, 3, 1]; cost 4")
    func ma209() throws {
        // [0 0 1 0; 1 0 0 0; 0 0 0 1; 0 1 0 0]; linearSumAssignment(rowCount: 4, columnCount: 4, maximize: true)
        let matrix: [[Int?]] = [[0, 0, 1, 0], [1, 0, 0, 0], [0, 0, 0, 1], [0, 1, 0, 0]]
        let assignment = try #require(linearSumAssignment(rowCount: 4, columnCount: 4, maximize: true) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2, 3])
        #expect(assignment.columns == [2, 0, 3, 1])
        #expect(assignment.cost == 4)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 4 && assignment.columns.count == 4)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (4, 4)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total > best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-210 lcg 6×6 digits (row-major draws % 10 from LCG(42))")
    func ma210() throws {
        // [4 6 8 3 4 6; 9 0 6 5 4 0; 2 4 8 9 0 9; 9 4 9 8 4 5; 0 7 6 2 2 5; 4 6 8 8 6 2]; linearSumAssignment(rowCount: 6, columnCount: 6)
        let matrix: [[Int?]] = [[4, 6, 8, 3, 4, 6], [9, 0, 6, 5, 4, 0], [2, 4, 8, 9, 0, 9], [9, 4, 9, 8, 4, 5], [0, 7, 6, 2, 2, 5], [4, 6, 8, 8, 6, 2]]
        let assignment = try #require(linearSumAssignment(rowCount: 6, columnCount: 6) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2, 3, 4, 5])
        #expect(assignment.columns == [3, 1, 4, 2, 0, 5])
        #expect(assignment.cost == 14)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 6 && assignment.columns.count == 6)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (6, 6)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-211 lcg 5×7 small range (many ties) (continuing the same LCG(42) stream)")
    func ma211() throws {
        // [1 2 1 1 2 2 1; 3 3 1 1 3 2 3; 2 3 1 3 1 3 1; 3 0 0 3 3 1 2; 1 3 3 0 0 1 3]; linearSumAssignment(rowCount: 5, columnCount: 7)
        let matrix: [[Int?]] = [[1, 2, 1, 1, 2, 2, 1], [3, 3, 1, 1, 3, 2, 3], [2, 3, 1, 3, 1, 3, 1], [3, 0, 0, 3, 3, 1, 2], [1, 3, 3, 0, 0, 1, 3]]
        let assignment = try #require(linearSumAssignment(rowCount: 5, columnCount: 7) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1, 2, 3, 4])
        #expect(assignment.columns == [0, 2, 4, 1, 3])
        #expect(assignment.cost == 3)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 5 && assignment.columns.count == 5)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (5, 7)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }

    @Test("MA-212 integers beyond 2^53: exact (Int arithmetic is exact; scipy rounds to float64 and returns the worse [0, 1])")
    func ma212() throws {
        // [9007199254740993 9007199254740992; 9007199254740992 9007199254740992]; linearSumAssignment(rowCount: 2, columnCount: 2)
        let matrix: [[Int?]] = [[9007199254740993, 9007199254740992], [9007199254740992, 9007199254740992]]
        let assignment = try #require(linearSumAssignment(rowCount: 2, columnCount: 2) { matrix[$0][$1] })
        #expect(assignment.rows == [0, 1])
        #expect(assignment.columns == [1, 0])
        #expect(assignment.cost == 18014398509481984)
        // Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column
        // twice, no forbidden pair, and the cost is the sum in `rows` order.
        #expect(assignment.rows.count == 2 && assignment.columns.count == 2)
        #expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)
        #expect(Set(assignment.columns).count == assignment.columns.count)
        var sum: Int = 0
        for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }
        #expect(sum == assignment.cost)
        // Brute force over every assignment of the shorter dimension into the longer one.
        func entry(_ a: Int, _ b: Int) -> Int? { matrix[a][b] }
        let (shorter, longer) = (2, 2)
        var taken = [Bool](repeating: false, count: longer)
        var best: Int?
        func place(_ a: Int, _ total: Int) {
            guard a < shorter else {
                if best == nil || total < best! { best = total }
                return
            }
            for b in 0 ..< longer where !taken[b] {
                guard let c = entry(a, b) else { continue }
                taken[b] = true
                place(a + 1, total + c)
                taken[b] = false
            }
        }
        place(0, 0)
        #expect(assignment.cost == best!, "optimal, by brute force: \(String(describing: best))")
    }
}
