# Planted bugs for SpectralGraphTheory; run with `just mutate SpectralGraphTheory`. See
# scripts/mutate.py.
#
# Known equivalent mutants (they survive by design):
#   rowoverflow   The row pass's overflow check: the degree pass checks the same sums again, so the
#                 trap only moves.
#   withoutloops  Keeping the loops in the shifted operators' rows: the degrees taken from those rows
#                 then count each loop, and the loop's entries add it back, so σI − L and σI − N
#                 are unchanged (dropping them only avoids that cancellation when a loop is heavy).
#   earlycheck    The mid-expansion test reading the top Ritz vector's first entry instead of its
#                 last: the first is the vector's overlap with the start vector, of order 1, so the
#                 misread test never accepts early; time only.
#   coupling      The couplings written into T at a thick restart: the next expansion step's full
#                 Gram–Schmidt pass writes the same column again.
#   dgks          No DGKS second pass: after the local pass the full pass removes only rounding, so
#                 the second pass almost never runs; it guards against rare loss of orthogonality.
#   icfill        The incomplete factor's fill update, its ground propagation, and the Jacobi
#   icground      diagonal: each only changes how good the preconditioner is, so conjugate
#   jacobi        gradients take more products to the same answer; time only.
#   truecheck     Accepting the recurrence's residual without the true-residual check: on the
#                 suite's inputs the two agree; it guards against drift on ill-conditioned systems.
#   groundrow     Leaving L x's entry at the ground: the solver never reads r at the ground (its
#                 preconditioners zero it), so only the stopping norm grows by that entry.
#   swapsign      The sign of a row exchange in the modular elimination: an exchange happens only
#                 when a pivot is 0 modulo a 62-bit prime, which no input of the suite meets.
#   unscale       Undoing the root-free iteration's block scaling: `_scaleIntoRange` has already
#                 brought every matrix near 1, so the block is never scaled.

TESTS = ["SpectralGraphTheoryTests"]

MUTANTS = [
    # Rows (GraphRows.swift)
    Mutant("zeroweight", "GraphRows.swift",
           "if weight == 0 { continue }",
           "", mode="stmt"),
    Mutant("negativeflag", "GraphRows.swift",
           "if weight < 0 { negative = true }",
           "", mode="stmt"),
    Mutant("loopflag", "GraphRows.swift",
           "if w == v { loop = true }",
           "", mode="stmt", nth=0),
    Mutant("loopflagunweighted", "GraphRows.swift",
           "if w == v { loop = true }",
           "", mode="stmt", nth=1),
    Mutant("rowoverflow", "GraphRows.swift",
           'precondition(sum.isFinite, "A sum of weights overflows Double")',
           "", mode="stmt"),

    # Matrices and operators (WeightedAdjacency.swift)
    Mutant("mergezero", "WeightedAdjacency.swift",
           "sum != 0",
           "true"),
    Mutant("mergeoverflow", "WeightedAdjacency.swift",
           'precondition(sum.isFinite, "A sum of weights overflows Double")',
           "", mode="stmt"),
    Mutant("symmetric", "WeightedAdjacency.swift",
           "!symmetric",
           "symmetric"),
    Mutant("normalizedentry", "WeightedAdjacency.swift",
           "-w / root[v] / root[u]",
           "-w / root[v] / root[v]"),
    Mutant("signlessloop", "WeightedAdjacency.swift",
           "diagonal = d[v] + loop",
           "diagonal = d[v]", mode="stmt"),
    Mutant("randomwalk", "WeightedAdjacency.swift",
           "entry = -w / d[v]",
           "entry = -w / d[u]", mode="stmt"),
    Mutant("withoutloops", "WeightedAdjacency.swift",
           "guard hasLoop else { return self }",
           "return self", mode="stmt"),
    Mutant("densenormalized", "WeightedAdjacency.swift",
           "a[v * n + v] = d[v] > 0 ? dl[v] / d[v] : 0",
           "a[v * n + v] = d[v] > 0 ? 1 : 0", mode="stmt"),
    Mutant("shifteddiagonal", "WeightedAdjacency.swift",
           "diagonal[v] = 2 - dl[v] / d[v]",
           "diagonal[v] = 1", mode="stmt"),
    Mutant("nullnormalized", "WeightedAdjacency.swift",
           "null[v] = d[v].squareRoot()",
           "null[v] = d[v]", mode="stmt"),

    # Lanczos
    Mutant("earlycheck", "Lanczos.swift",
           "abs(beta * y[(j - 1) * j + j - 1]) <= rule.threshold(theta)",
           "abs(beta * y[(j - 1) * j]) <= rule.threshold(theta)"),
    Mutant("relative", "Lanczos.swift",
           "tolerance * max(floor, abs(theta - shift))",
           "tolerance * max(floor, abs(theta))"),
    Mutant("coupling", "Lanczos.swift",
           "beta * y[(top - i) * size + size - 1]",
           "beta * y[(top - i) * size]"),
    Mutant("sign", "Lanczos.swift",
           "y[row] = sign * sum",
           "y[row] = sum", mode="stmt", nth=0),
    Mutant("dgks", "Lanczos.swift",
           "beta < _dgksRatio * before",
           "false"),

    # The grounded solver (GroundedLaplacian.swift)
    Mutant("icpivot", "GroundedLaplacian.swift",
           "toGround[i]",
           "0.0", nth=1),
    Mutant("icfill", "GroundedLaplacian.swift",
           "values[slot[b]] += fill",
           "values[slot[b]] -= fill", mode="stmt"),
    Mutant("icground", "GroundedLaplacian.swift",
           "toGround[a] += ca * toGround[i] / p",
           "", mode="stmt"),
    Mutant("primorder", "GroundedLaplacian.swift",
           "reached[size - 1 - i]",
           "reached[i]"),
    Mutant("cgstep", "GroundedLaplacian.swift",
           "_axpy(alpha, p, x, n)",
           "_axpy(0.5 * alpha, p, x, n)", mode="stmt"),
    Mutant("truecheck", "GroundedLaplacian.swift",
           "trueNorm <= target || trueNorm > 0.5 * lastTrueNorm",
           "true"),
    Mutant("noswitch", "GroundedLaplacian.swift",
           "!useFactor && sinceStart >= _jacobiIterations",
           "false"),
    Mutant("groundrow", "GroundedLaplacian.swift",
           "y[ground] = 0",
           "", mode="stmt"),
    Mutant("product", "GroundedLaplacian.swift",
           "sum += values[k] * (xv - x[Int(columns[k])])",
           "sum += values[k] * (xv + x[Int(columns[k])])", mode="stmt"),
    Mutant("breakdown", "GroundedLaplacian.swift",
           "pq > 0",
           "pq > 1e300"),
    Mutant("jacobi", "GroundedLaplacian.swift",
           "inverse[v] = 1 / d[v]",
           "inverse[v] = 1", mode="stmt"),

    # GTH elimination and the exact count (GroundedElimination.swift)
    Mutant("gthpivot", "GroundedElimination.swift",
           "toGround[j]",
           "0.0", nth=0),
    Mutant("gthground", "GroundedElimination.swift",
           "toGround[k] += f * toGround[j]",
           "", mode="stmt"),
    Mutant("gthfill", "GroundedElimination.swift",
           "target[i] += f * column[i]",
           "target[i] += 2 * f * column[i]", mode="stmt"),
    Mutant("energy", "GroundedElimination.swift",
           "sum += yj * yj / pivots[j]",
           "sum += yj / pivots[j]", mode="stmt", nth=0),
    Mutant("inversediagonal", "GroundedElimination.swift",
           "for i in j + 1 ..< size { y[i] += column[i] * yj }",
           "", mode="stmt", nth=1),
    Mutant("carry", "GroundedElimination.swift",
           "hi &+ mp.high &+ (lo != 0 ? 1 : 0)",
           "hi &+ mp.high"),
    Mutant("swapsign", "GroundedElimination.swift",
           "negated.toggle()",
           "", mode="stmt"),
    Mutant("crt", "GroundedElimination.swift",
           "a2 >= a1 % p2 ? a2 - a1 % p2 : a2 + (p2 - a1 % p2)",
           "a1 % p2 >= a2 ? a1 % p2 - a2 : a1 % p2 + (p2 - a2)"),
    Mutant("pivotproduct", "GroundedElimination.swift",
           "determinant = field.multiply(determinant, pivotRow[j])",
           "", mode="stmt"),
    Mutant("elimination", "GroundedElimination.swift",
           "row[k] = field.subtract(row[k], field.multiply(f, pivotRow[k]))",
           "row[k] = field.add(row[k], field.multiply(f, pivotRow[k]))", mode="stmt"),

    # The quantities (SpectralCore.swift)
    Mutant("exactgate", "SpectralCore.swift",
           "estimate < 0x1p100 && hasSmallIntegerWeights",
           "estimate < 0x1p53 && hasSmallIntegerWeights"),
    Mutant("integral", "SpectralCore.swift",
           "$0 == $0.rounded(.towardZero) && $0 < 0x1p53",
           "$0 < 0x1p53"),
    Mutant("rayleigh", "SpectralCore.swift",
           "energy / 2 / length",
           "energy / length"),
    Mutant("canonicalsign", "SpectralCore.swift",
           "if t < 0 { for i in x.indices { x[i] = -x[i] } }",
           "if t > 0 { for i in x.indices { x[i] = -x[i] } }", mode="stmt"),
    Mutant("signthreshold", "SpectralCore.swift",
           "abs(t) >= 1e-4 * largest",
           "abs(t) >= 1e-9 * largest"),
    Mutant("project", "SpectralCore.swift",
           "x[i] -= dot * null[i]",
           "", mode="stmt"),
    Mutant("ratio", "SpectralCore.swift",
           "min(_shiftInvertRatio(tolerance), 20 * Double(n))",
           "Double.infinity"),
    Mutant("finalstep", "SpectralCore.swift",
           "vector = next",
           "", mode="stmt"),
    Mutant("sinormalized", "SpectralCore.swift",
           "for v in 0 ..< n { b[v] = root[v] * input[v] }",
           "for v in 0 ..< n { b[v] = input[v] }", mode="stmt"),
    Mutant("kemeny", "SpectralCore.swift",
           "volume * (weighted - elimination.energy(stationary))",
           "(weighted - elimination.energy(stationary))"),
    Mutant("kirchhoff", "SpectralCore.swift",
           "Double(n) * trace - total",
           "Double(n - 1) * trace - total"),
    Mutant("component", "SpectralCore.swift",
           "guard seen[source] else { return nil }",
           "", mode="stmt"),
    Mutant("radiusnegated", "SpectralCore.swift",
           "max(largest, negated, 0)",
           "max(largest, 0)"),
    Mutant("ordering", "SpectralCore.swift",
           "x[b] - x[a] <= 1e-8 * largest",
           "x[b] - x[a] <= 1e-2 * largest"),

    # Dense eigenvalues (SymmetricEigensolver.swift)
    Mutant("sterfshift", "SymmetricEigensolver.swift",
           "sigma = p - root / (sigma + (sigma < 0 ? -r : r))",
           "sigma = p", mode="stmt", nth=0),
    Mutant("sterfqr", "SymmetricEigensolver.swift",
           "d[i] = oldGamma + (alpha - gamma)",
           "d[i] = oldGamma + (gamma - alpha)", mode="stmt"),
    Mutant("sterf2x2", "SymmetricEigensolver.swift",
           "(d[l], d[l + 1]) = _eigenvalues2(d[l], e[l].squareRoot(), d[l + 1])",
           "(d[l], d[l + 1]) = (d[l], d[l + 1])", mode="stmt"),
    Mutant("dlae2", "SymmetricEigensolver.swift",
           "(larger / rt1) * smaller - (b / rt1) * b",
           "(larger / rt1) * smaller + (b / rt1) * b", nth=0),
    Mutant("deflate", "SymmetricEigensolver.swift",
           "abs(e[m]) <= eps2 * abs(d[m] * d[m + 1])",
           "abs(e[m]) <= 1e-6 * abs(d[m] * d[m + 1])"),
    Mutant("unscale", "SymmetricEigensolver.swift",
           "for i in start ... endStart { d[i] /= scale }",
           "", mode="stmt"),
]
