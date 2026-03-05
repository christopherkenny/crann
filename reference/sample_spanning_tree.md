# Sample a uniform random spanning tree

Samples a spanning tree uniformly at random from the set of all spanning
trees using Wilson's (1996) loop-erased random walk algorithm.

## Usage

``` r
sample_spanning_tree(graph)
```

## Arguments

- graph:

  An `adj` object representing a connected undirected graph.

## Value

An `adj` object representing a spanning tree of `graph`.

## References

Wilson, D.B. (1996). Generating random spanning trees more quickly than
the cover time. *Proceedings of the 28th Annual ACM Symposium on Theory
of Computing*, 296–303.
[doi:10.1145/237814.237880](https://doi.org/10.1145/237814.237880)

## See also

[`enumerate_spanning_trees()`](http://christophertkenny.com/crann/reference/enumerate_spanning_trees.md),
[`minimum_spanning_tree()`](http://christophertkenny.com/crann/reference/minimum_spanning_tree.md)

## Examples

``` r
set.seed(1)
g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
sample_spanning_tree(g)
#> <adj[3]>
#> [1] {2}    {1, 3} {2}   
```
