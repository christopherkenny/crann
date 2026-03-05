# Enumerate all spanning trees

Enumerates all spanning trees of a connected undirected graph using
Winter's (1986) contraction-based algorithm. The algorithm has
worst-case time complexity O(n + m + nt) and space complexity O(n^2),
where n is the number of vertices, m the number of edges, and t the
number of spanning trees.

## Usage

``` r
enumerate_spanning_trees(graph)
```

## Arguments

- graph:

  An `adj` object representing a connected undirected graph without
  self-loops or duplicate edges.

## Value

A list of `adj` objects, one per spanning tree.

## References

Winter, P. (1986). An algorithm for the enumeration of spanning trees.
*BIT Numerical Mathematics*, 26(1), 44–62.
[doi:10.1007/BF01939361](https://doi.org/10.1007/BF01939361)

## Examples

``` r
# Triangle: 3 spanning trees
g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
trees <- enumerate_spanning_trees(g)
length(trees)
#> [1] 3
```
