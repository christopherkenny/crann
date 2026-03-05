# Fundamental cycles of a spanning tree

Returns the fundamental cycles of a spanning tree with respect to the
original graph. There is one fundamental cycle per non-tree edge (m -
n + 1 total), formed by adding that edge to the unique path between its
endpoints in the spanning tree.

## Usage

``` r
fundamental_cycles(graph, tree)
```

## Arguments

- graph:

  An `adj` object representing a connected undirected graph.

- tree:

  An `adj` object representing a spanning tree of `graph`.

## Value

A list of `adj` objects, one per non-tree edge. Each `adj` represents
the cycle as a subgraph of `graph`.

## See also

[`fundamental_cuts()`](http://christophertkenny.com/crann/reference/fundamental_cuts.md)

## Examples

``` r
g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
t <- minimum_spanning_tree(g)
fundamental_cycles(g, t)
#> [[1]]
#> <adj[3]>
#> [1] {2, 3} {1, 3} {1, 2}
#> 
```
