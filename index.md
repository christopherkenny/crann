# crann

`crann` (Irish for “tree”) implements spanning tree algorithms for
undirected graphs represented as
[`adj`](https://christophertkenny.github.io/adj/) adjacency lists. It
provides tools for counting, enumerating, sampling, and analyzing the
spanning trees of a graph.

## Installation

You can install the development version of `crann` from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("christopherkenny/crann")
```

## Examples

``` r
library(crann)
library(adj)
```

We build a complete graph on four vertices (K4) to use throughout these
examples.

``` r
k4 <- adj(list(c(2L, 3L, 4L), c(1L, 3L, 4L), c(1L, 2L, 4L), c(1L, 2L, 3L)))
k4
#> <adj[4]>
#> [1] {2, 3, 4} {1, 3, 4} {1, 2, 4} {1, 2, 3}
```

### Counting spanning trees

[`count_spanning_trees()`](http://christophertkenny.com/crann/reference/count_spanning_trees.md)
uses Kirchhoff’s matrix tree theorem to count spanning trees exactly. K4
has 16.

``` r
count_spanning_trees(k4)
#> [1] 16
```

### Enumerating spanning trees

[`enumerate_spanning_trees()`](http://christophertkenny.com/crann/reference/enumerate_spanning_trees.md)
returns all spanning trees as a list of `adj` objects using Winter’s
(1986) contraction-based algorithm.

``` r
trees <- enumerate_spanning_trees(k4)
length(trees)
#> [1] 16
trees[[1]]
#> <adj[4]>
#> [1] {2}    {3, 1} {4, 2} {3}
```

For downstream computation,
[`enumerate_spanning_trees_edges()`](http://christophertkenny.com/crann/reference/enumerate_spanning_trees_edges.md)
returns the same trees as a compact integer matrix with n−1 rows and 2t
columns. Columns 2k−1 and 2k hold the edge endpoints of spanning tree k.
This avoids per-tree memory allocation and is substantially faster for
graphs with many spanning trees.

``` r
mat <- enumerate_spanning_trees_edges(k4)
dim(mat)  # (n-1) x (2 * n_trees)
#> [1]  3 32
mat[, 1:4]  # first two trees
#>      [,1] [,2] [,3] [,4]
#> [1,]    4    3    4    3
#> [2,]    3    2    3    2
#> [3,]    2    1    3    1
```

### Minimum spanning tree

[`minimum_spanning_tree()`](http://christophertkenny.com/crann/reference/minimum_spanning_tree.md)
finds a minimum spanning tree using Kruskal’s algorithm. Edges are
supplied in the same canonical order as `get_edges()`: pairs (u, v) with
u \< v, sorted by u then v.

``` r
# Assign weights to the 6 edges of K4: {1,2}, {1,3}, {1,4}, {2,3}, {2,4}, {3,4}
w <- c(4, 1, 3, 2, 5, 6)
mst <- minimum_spanning_tree(k4, weights = w)
mst
#> <adj[4]>
#> [1] {3, 4} {3}    {1, 2} {1}
```

### Sampling a random spanning tree

[`sample_spanning_tree()`](http://christophertkenny.com/crann/reference/sample_spanning_tree.md)
draws a spanning tree uniformly at random using Wilson’s (1996)
loop-erased random walk algorithm.

``` r
set.seed(42)
sample_spanning_tree(k4)
#> <adj[4]>
#> [1] {2, 3, 4} {1}       {1}       {1}
```

### Structural analysis

Given a graph and one of its spanning trees,
[`fundamental_cycles()`](http://christophertkenny.com/crann/reference/fundamental_cycles.md)
returns the m−n+1 fundamental cycles (one per non-tree edge) and
[`fundamental_cuts()`](http://christophertkenny.com/crann/reference/fundamental_cuts.md)
returns the n−1 fundamental cuts (one per tree edge), each as a list of
`adj` objects.

``` r
tree <- trees[[1]]

cycles <- fundamental_cycles(k4, tree)
length(cycles)  # m - n + 1 = 6 - 4 + 1 = 3
#> [1] 3
cycles[[1]]
#> <adj[4]>
#> [1] {2, 3} {1, 3} {2, 1} {}

cuts <- fundamental_cuts(k4, tree)
length(cuts)  # n - 1 = 3
#> [1] 3
cuts[[1]]
#> <adj[4]>
#> [1] {2, 3, 4} {1}       {1}       {1}
```

### Validation

[`is_spanning_tree()`](http://christophertkenny.com/crann/reference/is_spanning_tree.md)
checks whether a graph is structurally a spanning tree (connected,
acyclic, n−1 edges).
[`is_spanning_tree_of()`](http://christophertkenny.com/crann/reference/is_spanning_tree_of.md)
additionally checks that every tree edge appears in the host graph.

``` r
is_spanning_tree(tree)
#> [1] TRUE
is_spanning_tree_of(tree, k4)
#> [1] TRUE
```
