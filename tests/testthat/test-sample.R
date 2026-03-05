test_that('sample_spanning_tree returns a spanning tree', {
  g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
  set.seed(1)
  t <- sample_spanning_tree(g)
  expect_true(is_spanning_tree_of(t, g))
})

test_that('sample_spanning_tree works on K4 and path', {
  k4 <- adj::adj(list(c(2L, 3L, 4L), c(1L, 3L, 4L), c(1L, 2L, 4L), c(1L, 2L, 3L)))
  set.seed(1)
  expect_true(is_spanning_tree_of(sample_spanning_tree(k4), k4))

  path <- adj::adj(list(c(2L), c(1L, 3L), c(2L, 4L), c(3L)))
  expect_true(is_spanning_tree_of(sample_spanning_tree(path), path))
})

test_that('sample_spanning_tree is reproducible with set.seed', {
  g <- adj::adj(list(c(2L, 3L, 4L), c(1L, 3L, 4L), c(1L, 2L, 4L), c(1L, 2L, 3L)))
  set.seed(42)
  t1 <- sample_spanning_tree(g)
  set.seed(42)
  t2 <- sample_spanning_tree(g)
  expect_identical(t1, t2)
})

test_that('sample_spanning_tree samples approximately uniformly on K3', {
  # K3 has 3 spanning trees; each should appear ~1/3 of the time
  g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
  trees <- enumerate_spanning_trees(g)

  to_edge_set <- function(t) {
    n <- length(t)
    es <- character(0)
    for (u in seq_len(n)) {
      for (v in t[[u]]) {
        if (u < v) es <- c(es, paste(u, v, sep = '-'))
      }
    }
    paste(sort(es), collapse = '|')
  }

  known <- vapply(trees, to_edge_set, character(1L))
  n_rep <- 3000L
  counts <- integer(3L)
  set.seed(7)
  for (k in seq_len(n_rep)) {
    s <- to_edge_set(sample_spanning_tree(g))
    idx <- match(s, known)
    counts[idx] <- counts[idx] + 1L
  }
  # Chi-squared goodness-of-fit: expected n_rep/3 each
  chi2 <- sum((counts - n_rep / 3)^2 / (n_rep / 3))
  # p-value > 0.001 with df=2 (critical value ~13.8)
  expect_lt(chi2, 13.8)
})

test_that('sample_spanning_tree validates input', {
  expect_snapshot(error = TRUE, sample_spanning_tree(list(c(2L), c(1L))))
  expect_snapshot(error = TRUE, sample_spanning_tree(adj::adj(list(integer(0L)))))
})
