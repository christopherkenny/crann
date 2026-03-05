# Minimum spanning tree

Finds a minimum spanning tree of a connected undirected graph using
Kruskal's algorithm. When `weights` is `NULL` (the default), all edges
are treated as having equal weight and any spanning tree is returned.

## Usage

``` r
minimum_spanning_tree(graph, weights = NULL)
```

## Arguments

- graph:

  An `adj` object representing a connected undirected graph.

- weights:

  A numeric vector of edge weights, one per edge. Edges are ordered by
  iterating vertices `u = 1, ..., n` and for each `u` iterating over
  `graph[[u]]` retaining only neighbors `v > u`. Pass `NULL` for uniform
  weights.

## Value

An `adj` object representing the minimum spanning tree.

## See also

[`is_spanning_tree()`](http://christophertkenny.com/crann/reference/is_spanning_tree.md)
to validate a spanning tree.

## Examples

``` r
g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
minimum_spanning_tree(g)
#> <adj[3]>
#> [1] {2, 3} {1}    {1}   
```
