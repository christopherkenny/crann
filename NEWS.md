# crann (development version)

* `count_spanning_trees()` counts spanning trees via Kirchhoff's matrix tree theorem.
* `enumerate_spanning_trees()` enumerates all spanning trees of a connected undirected graph using Winter's (1986) contraction-based algorithm.
* `enumerate_spanning_trees_edges()` enumerates all spanning trees as a compact integer matrix (n-1 rows, 2t columns), avoiding per-tree R memory allocation for a ~9x speedup over `enumerate_spanning_trees()` on dense graphs.
* `fundamental_cuts()` returns the fundamental cuts of a spanning tree.
* `fundamental_cycles()` returns the fundamental cycles of a spanning tree.
* `is_spanning_tree()` tests whether a graph is structurally a spanning tree (connected and acyclic).
* `is_spanning_tree_of()` tests whether a graph is a spanning tree of another graph (subgraph membership check).
* `minimum_spanning_tree()` finds a minimum spanning tree using Kruskal's algorithm.
* `sample_spanning_tree()` samples a spanning tree uniformly at random using Wilson's (1996) loop-erased random walk algorithm.
