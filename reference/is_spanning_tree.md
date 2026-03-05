# Test if a graph is a spanning tree

Returns `TRUE` if `tree` is a spanning tree: a connected acyclic graph
with exactly n-1 edges. To additionally check that `tree` uses only
edges from a reference graph, see
[`is_spanning_tree_of()`](http://christophertkenny.com/crann/reference/is_spanning_tree_of.md).

## Usage

``` r
is_spanning_tree(tree)
```

## Arguments

- tree:

  An `adj` object to test.

## Value

A logical scalar.

## See also

[`is_spanning_tree_of()`](http://christophertkenny.com/crann/reference/is_spanning_tree_of.md),
[`minimum_spanning_tree()`](http://christophertkenny.com/crann/reference/minimum_spanning_tree.md),
[`enumerate_spanning_trees()`](http://christophertkenny.com/crann/reference/enumerate_spanning_trees.md)

## Examples

``` r
g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
t <- minimum_spanning_tree(g)
is_spanning_tree(t)
#> [1] TRUE
```
