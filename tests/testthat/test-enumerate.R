test_that('path graph P3 has 1 spanning tree', {
  g <- adj::adj(list(c(2L), c(1L, 3L), c(2L)))
  trees <- enumerate_spanning_trees(g)
  expect_length(trees, 1L)
  expect_s3_class(trees[[1L]], 'adj')
})

test_that('K3 has 3 spanning trees', {
  g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
  trees <- enumerate_spanning_trees(g)
  expect_length(trees, 3L)
  expect_true(all(vapply(trees, is_spanning_tree, logical(1L))))
})

test_that('K4 has 16 spanning trees', {
  g <- adj::adj(list(c(2L, 3L, 4L), c(1L, 3L, 4L), c(1L, 2L, 4L), c(1L, 2L, 3L)))
  trees <- enumerate_spanning_trees(g)
  expect_length(trees, 16L)
})

test_that('4-cycle has 4 spanning trees', {
  g <- adj::adj(list(c(2L, 4L), c(1L, 3L), c(2L, 4L), c(1L, 3L)))
  trees <- enumerate_spanning_trees(g)
  expect_length(trees, 4L)
})

test_that('path graph P4 has 1 spanning tree', {
  g <- adj::adj(list(c(2L), c(1L, 3L), c(2L, 4L), c(3L)))
  trees <- enumerate_spanning_trees(g)
  expect_length(trees, 1L)
})

test_that('spanning trees have correct structure', {
  # K3: each spanning tree has n=3 vertices and n-1=2 edges
  g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
  trees <- enumerate_spanning_trees(g)
  expect_true(all(lengths(trees) == 3L))
  expect_true(all(vapply(trees, \(t) sum(lengths(t)) %/% 2L == 2L, logical(1L))))
})

test_that('spanning trees are distinct', {
  g <- adj::adj(list(c(2L, 3L, 4L), c(1L, 3L, 4L), c(1L, 2L, 4L), c(1L, 2L, 3L)))
  trees <- enumerate_spanning_trees(g)
  # Convert each to a sorted edge set for comparison
  to_edge_set <- function(t) {
    n <- length(t)
    edges <- character(0L)
    for (u in seq_len(n)) {
      for (v in t[[u]]) {
        if (u < v) edges <- c(edges, paste(u, v))
      }
    }
    paste(sort(edges), collapse = '|')
  }
  edge_sets <- vapply(trees, to_edge_set, character(1L))
  expect_length(unique(edge_sets), length(trees))
})

test_that('graph input validation works', {
  expect_snapshot(
    error = TRUE,
    enumerate_spanning_trees(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
  )
  expect_snapshot(
    error = TRUE,
    enumerate_spanning_trees(adj::adj(list(integer(0L))))
  )
})

test_that('enumerate_spanning_trees_edges returns correct dimensions', {
  g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
  m <- enumerate_spanning_trees_edges(g)
  # K3: 3 trees, n-1=2 edges -> 2 x 6 matrix
  expect_equal(dim(m), c(2L, 6L))
  expect_type(m, 'integer')
})

test_that('enumerate_spanning_trees_edges agrees with enumerate_spanning_trees', {
  g <- adj::adj(list(c(2L, 3L, 4L), c(1L, 3L, 4L), c(1L, 2L, 4L), c(1L, 2L, 3L)))
  adj_trees <- enumerate_spanning_trees(g)
  mat <- enumerate_spanning_trees_edges(g)

  # Convert adj trees to sorted edge sets
  to_edge_set_adj <- function(t) {
    n <- length(t)
    edges <- character(0L)
    for (u in seq_len(n)) {
      for (v in t[[u]]) {
        if (u < v) edges <- c(edges, paste(u, v))
      }
    }
    paste(sort(edges), collapse = '|')
  }
  # Convert matrix columns to sorted edge sets
  n1 <- nrow(mat)
  to_edge_set_mat <- function(k) {
    u <- mat[, 2L * k - 1L]
    v <- mat[, 2L * k]
    edges <- ifelse(u < v, paste(u, v), paste(v, u))
    paste(sort(edges), collapse = '|')
  }

  adj_sets <- sort(vapply(adj_trees, to_edge_set_adj, character(1L)))
  mat_sets <- sort(vapply(seq_len(ncol(mat) %/% 2L), to_edge_set_mat, character(1L)))
  expect_equal(adj_sets, mat_sets)
})

test_that('enumerate_spanning_trees_edges input validation works', {
  expect_snapshot(
    error = TRUE,
    enumerate_spanning_trees_edges(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
  )
  expect_snapshot(
    error = TRUE,
    enumerate_spanning_trees_edges(adj::adj(list(integer(0L))))
  )
})
