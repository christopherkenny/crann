test_that('count_spanning_trees matches known values', {
  k3 <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
  k4 <- adj::adj(list(c(2L, 3L, 4L), c(1L, 3L, 4L), c(1L, 2L, 4L), c(1L, 2L, 3L)))
  cycle4 <- adj::adj(list(c(2L, 4L), c(1L, 3L), c(2L, 4L), c(1L, 3L)))
  path <- adj::adj(list(c(2L), c(1L, 3L), c(2L, 4L), c(3L)))

  expect_equal(count_spanning_trees(k3), 3)
  expect_equal(count_spanning_trees(k4), 16)
  expect_equal(count_spanning_trees(cycle4), 4)
  expect_equal(count_spanning_trees(path), 1)
})

test_that('count_spanning_trees returns numeric', {
  g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
  expect_type(count_spanning_trees(g), 'double')
})

test_that('count_spanning_trees agrees with enumerate_spanning_trees', {
  g <- adj::adj(list(c(2L, 3L, 4L), c(1L, 3L, 4L), c(1L, 2L, 4L), c(1L, 2L, 3L)))
  expect_equal(count_spanning_trees(g), length(enumerate_spanning_trees(g)))
})

test_that('count_spanning_trees validates input', {
  expect_snapshot(error = TRUE, count_spanning_trees(list(1L, 2L)))
  expect_snapshot(error = TRUE, count_spanning_trees(adj::adj(list(integer(0L)))))
})
