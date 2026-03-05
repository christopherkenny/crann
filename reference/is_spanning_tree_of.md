# Test if a graph is a spanning tree of another graph

Returns `TRUE` if `tree` is a spanning tree of `graph`: a connected
acyclic subgraph that spans all vertices and uses only edges present in
`graph`.

## Usage

``` r
is_spanning_tree_of(tree, graph)
```

## Arguments

- tree:

  An `adj` object to test.

- graph:

  An `adj` object representing a connected undirected graph.

## Value

A logical scalar.

## See also

[`is_spanning_tree()`](http://christophertkenny.com/crann/reference/is_spanning_tree.md),
[`minimum_spanning_tree()`](http://christophertkenny.com/crann/reference/minimum_spanning_tree.md),
[`enumerate_spanning_trees()`](http://christophertkenny.com/crann/reference/enumerate_spanning_trees.md)

## Examples

``` r
g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
t <- minimum_spanning_tree(g)
is_spanning_tree_of(t, g)
#> [1] TRUE
```
