# Fundamental cuts of a spanning tree

Returns the fundamental cuts of a spanning tree with respect to the
original graph. There is one fundamental cut per tree edge (n - 1
total), consisting of all edges in the graph that cross the bipartition
induced by removing that tree edge.

## Usage

``` r
fundamental_cuts(graph, tree)
```

## Arguments

- graph:

  An `adj` object representing a connected undirected graph.

- tree:

  An `adj` object representing a spanning tree of `graph`.

## Value

A list of `adj` objects, one per tree edge. Each `adj` represents the
cut as a subgraph of `graph`.

## See also

[`fundamental_cycles()`](http://christophertkenny.com/crann/reference/fundamental_cycles.md)

## Examples

``` r
g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
t <- minimum_spanning_tree(g)
fundamental_cuts(g, t)
#> [[1]]
#> <adj[3]>
#> [1] {2}    {1, 3} {2}   
#> 
#> [[2]]
#> <adj[3]>
#> [1] {3}    {3}    {1, 2}
#> 
```
