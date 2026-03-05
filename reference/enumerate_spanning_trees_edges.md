# Enumerate spanning trees as an edge matrix

Returns a compact integer matrix encoding all spanning trees of a
connected undirected graph. The matrix has n-1 rows and 2t columns,
where n is the number of vertices and t is the number of spanning trees.
For spanning tree k (1-indexed), columns 2k-1 and 2k hold the u and v
endpoints (1-indexed vertex IDs) of each of the n-1 edges.

## Usage

``` r
enumerate_spanning_trees_edges(graph)
```

## Arguments

- graph:

  An `adj` object representing a connected undirected graph without
  self-loops or duplicate edges.

## Value

An integer matrix with n-1 rows and 2t columns.

## Details

This function is substantially faster than
[`enumerate_spanning_trees()`](http://christophertkenny.com/crann/reference/enumerate_spanning_trees.md)
for graphs with many spanning trees because it avoids per-tree R memory
allocation: the entire output is a single integer matrix allocation.

## References

Winter, P. (1986). An algorithm for the enumeration of spanning trees.
*BIT Numerical Mathematics*, 26(1), 44–62.
[doi:10.1007/BF01939361](https://doi.org/10.1007/BF01939361)

## Examples

``` r
# Triangle: 3 spanning trees, 2 edges each -> 2 x 6 matrix
g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
enumerate_spanning_trees_edges(g)
#>      [,1] [,2] [,3] [,4] [,5] [,6]
#> [1,]    3    2    3    2    3    1
#> [2,]    2    1    3    1    2    1
```
