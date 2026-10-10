"""Literals of CliqueConformanceTests.swift: ref.py's values for the graphs it uses."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref
for cell in ["U: K(0..2), 2-3", "U: 0-1, 0-2, 1-2, 2-3, 3-0, 3-1", "U: nx(karate_club)"]:
    for op in ["maximalCliques", "maximumClique", "cliqueNumber", "coreNumbers", "degeneracyOrdering", "triangleCounts", "clusteringCoefficients", "triangleCount", "transitivity", "averageClustering", "maximalCliques.count"]:
        print(cell, "|", op, "|", ref.evaluate(cell, op))
