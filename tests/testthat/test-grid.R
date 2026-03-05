grid_graph <- function(nrow, ncol) {
  nv <- nrow * ncol
  nbrs <- vector('list', nv)
  for (i in seq_len(nv)) nbrs[[i]] <- integer(0L)
  for (r in seq_len(nrow)) {
    for (c in seq_len(ncol)) {
      v <- (r - 1L) * ncol + c
      if (c < ncol) {
        w <- v + 1L
        nbrs[[v]] <- c(nbrs[[v]], w)
        nbrs[[w]] <- c(nbrs[[w]], v)
      }
      if (r < nrow) {
        w <- v + ncol
        nbrs[[v]] <- c(nbrs[[v]], w)
        nbrs[[w]] <- c(nbrs[[w]], v)
      }
    }
  }
  adj::adj(nbrs)
}

g3x3 <- grid_graph(3L, 3L) # 9 vertices, 12 edges
g3x4 <- grid_graph(3L, 4L) # 12 vertices, 17 edges

test_that('count_spanning_trees is correct for grid graphs', {
  expect_equal(count_spanning_trees(g3x3), 192)
  expect_equal(count_spanning_trees(g3x4), 2415)
})

test_that('enumerate_spanning_trees agrees with count for grid graphs', {
  expect_length(enumerate_spanning_trees(g3x3), 192L)
  expect_length(enumerate_spanning_trees(g3x4), 2415L)
})

test_that('minimum_spanning_tree works on grid graphs', {
  expect_true(is_spanning_tree_of(minimum_spanning_tree(g3x3), g3x3))
  expect_true(is_spanning_tree_of(minimum_spanning_tree(g3x4), g3x4))
})

test_that('sample_spanning_tree works on grid graphs', {
  set.seed(1)
  expect_true(is_spanning_tree_of(sample_spanning_tree(g3x3), g3x3))
  expect_true(is_spanning_tree_of(sample_spanning_tree(g3x4), g3x4))
})

test_that('fundamental_cycles returns correct count for grid graphs', {
  # 3x3: m=12, n=9, cycles = m - n + 1 = 4
  expect_length(fundamental_cycles(g3x3, minimum_spanning_tree(g3x3)), 4L)
  # 3x4: m=17, n=12, cycles = m - n + 1 = 6
  expect_length(fundamental_cycles(g3x4, minimum_spanning_tree(g3x4)), 6L)
})

test_that('fundamental_cuts returns correct count for grid graphs', {
  expect_length(fundamental_cuts(g3x3, minimum_spanning_tree(g3x3)), 8L) # n-1 = 8
  expect_length(fundamental_cuts(g3x4, minimum_spanning_tree(g3x4)), 11L) # n-1 = 11
})
