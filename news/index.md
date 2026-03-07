# Changelog

## crann 0.0.1

- [`count_spanning_trees()`](http://christophertkenny.com/crann/reference/count_spanning_trees.md)
  counts spanning trees via Kirchhoff’s matrix tree theorem.
- [`enumerate_spanning_trees()`](http://christophertkenny.com/crann/reference/enumerate_spanning_trees.md)
  enumerates all spanning trees of a connected undirected graph using
  Winter’s (1986) contraction-based algorithm.
- [`enumerate_spanning_trees_edges()`](http://christophertkenny.com/crann/reference/enumerate_spanning_trees_edges.md)
  enumerates all spanning trees as a compact integer matrix (n-1 rows,
  2t columns), avoiding per-tree R memory allocation for a ~9x speedup
  over
  [`enumerate_spanning_trees()`](http://christophertkenny.com/crann/reference/enumerate_spanning_trees.md)
  on dense graphs.
- [`fundamental_cuts()`](http://christophertkenny.com/crann/reference/fundamental_cuts.md)
  returns the fundamental cuts of a spanning tree.
- [`fundamental_cycles()`](http://christophertkenny.com/crann/reference/fundamental_cycles.md)
  returns the fundamental cycles of a spanning tree.
- [`is_spanning_tree()`](http://christophertkenny.com/crann/reference/is_spanning_tree.md)
  tests whether a graph is structurally a spanning tree (connected and
  acyclic).
- [`is_spanning_tree_of()`](http://christophertkenny.com/crann/reference/is_spanning_tree_of.md)
  tests whether a graph is a spanning tree of another graph (subgraph
  membership check).
- [`minimum_spanning_tree()`](http://christophertkenny.com/crann/reference/minimum_spanning_tree.md)
  finds a minimum spanning tree using Kruskal’s algorithm.
- [`sample_spanning_tree()`](http://christophertkenny.com/crann/reference/sample_spanning_tree.md)
  samples a spanning tree uniformly at random using Wilson’s (1996)
  loop-erased random walk algorithm.
