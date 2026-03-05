# Count spanning trees

Counts the number of spanning trees of a connected undirected graph
using Kirchhoff's matrix tree theorem: the count equals the determinant
of any (n-1) x (n-1) cofactor of the graph Laplacian.

## Usage

``` r
count_spanning_trees(graph)
```

## Arguments

- graph:

  An `adj` object representing a connected undirected graph.

## Value

A `numeric` scalar. (Integer-valued but returned as `numeric` since
counts can exceed `.Machine$integer.max` for dense graphs.)

## See also

[`enumerate_spanning_trees()`](http://christophertkenny.com/crann/reference/enumerate_spanning_trees.md)
to list all spanning trees.

## Examples

``` r
# Triangle: 3 spanning trees
g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
count_spanning_trees(g)
#> [1] 3
```
