test_that('minimum_spanning_tree returns a spanning tree', {
  g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
  t <- minimum_spanning_tree(g)
  expect_true(is_spanning_tree_of(t, g))
})

test_that('minimum_spanning_tree works on path and K4', {
  path <- adj::adj(list(c(2L), c(1L, 3L), c(2L, 4L), c(3L)))
  expect_true(is_spanning_tree_of(minimum_spanning_tree(path), path))

  k4 <- adj::adj(list(c(2L, 3L, 4L), c(1L, 3L, 4L), c(1L, 2L, 4L), c(1L, 2L, 3L)))
  expect_true(is_spanning_tree_of(minimum_spanning_tree(k4), k4))
})

test_that('minimum_spanning_tree respects weights', {
  # 4-cycle: edges in order (1,2), (1,4), (2,3), (3,4)
  # Give weight 1 to (1,2) and (2,3), weight 2 to others
  # MST must include (1,2) and (2,3) plus one of (1,4) or (3,4)
  g <- adj::adj(list(c(2L, 4L), c(1L, 3L), c(2L, 4L), c(1L, 3L)))
  w <- c(1, 2, 1, 2) # edges: (1,2)=1, (1,4)=2, (2,3)=1, (3,4)=2
  t <- minimum_spanning_tree(g, weights = w)
  expect_true(is_spanning_tree_of(t, g))
  # MST weight should be 4 (1+1+2)
  edge_weight <- function(tree, weights, g) {
    edges_g <- mst_edges(lapply(seq_len(length(g)), function(i) g[[i]]), length(g))
    total <- 0
    for (u in seq_len(length(tree))) {
      for (v in tree[[u]]) {
        if (u < v) {
          idx <- which(edges_g[, 1L] == u & edges_g[, 2L] == v)
          total <- total + weights[idx]
        }
      }
    }
    total
  }
  expect_equal(edge_weight(t, w, g), 4)
})

test_that('minimum_spanning_tree validates input', {
  expect_snapshot(error = TRUE, minimum_spanning_tree(list(1L, 2L)))
  g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
  expect_snapshot(error = TRUE, minimum_spanning_tree(g, weights = c(1, 2)))
})
