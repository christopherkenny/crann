g_k3 <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
g_k4 <- adj::adj(list(c(2L, 3L, 4L), c(1L, 3L, 4L), c(1L, 2L, 4L), c(1L, 2L, 3L)))

# --- is_spanning_tree ---

test_that('is_spanning_tree returns TRUE for valid spanning trees', {
  expect_true(is_spanning_tree(minimum_spanning_tree(g_k3)))
  expect_true(all(vapply(enumerate_spanning_trees(g_k3), is_spanning_tree, logical(1L))))
})

test_that('is_spanning_tree returns FALSE for non-trees', {
  expect_false(is_spanning_tree(list(c(2L), c(1L, 3L), c(2L))))
  expect_false(is_spanning_tree(g_k3)) # too many edges
  expect_false(is_spanning_tree(adj::adj(list(c(2L), c(1L), c(4L), c(3L))))) # disconnected
})

# --- is_spanning_tree_of ---

test_that('is_spanning_tree_of returns TRUE for valid spanning trees', {
  expect_true(is_spanning_tree_of(minimum_spanning_tree(g_k3), g_k3))
  expect_true(all(vapply(enumerate_spanning_trees(g_k3), is_spanning_tree_of, logical(1L), g_k3)))
})

test_that('is_spanning_tree_of returns FALSE for invalid inputs', {
  expect_false(is_spanning_tree_of(list(c(2L), c(1L, 3L), c(2L)), g_k3))
  expect_false(is_spanning_tree_of(minimum_spanning_tree(g_k4), g_k3)) # wrong n
  expect_false(is_spanning_tree_of(g_k3, g_k3)) # too many edges
  # edge (1,3) not in a graph where only (1,2) and (2,3) exist
  g_path <- adj::adj(list(c(2L), c(1L, 3L), c(2L)))
  t_bad <- adj::adj(list(c(2L, 3L), c(1L), c(1L)))
  expect_false(is_spanning_tree_of(t_bad, g_path))
})

# --- fundamental_cycles ---

test_that('fundamental_cycles returns m - n + 1 cycles', {
  # K3: m=3, n=3 -> 1 cycle
  t <- minimum_spanning_tree(g_k3)
  cyc <- fundamental_cycles(g_k3, t)
  expect_length(cyc, 1L)
  expect_s3_class(cyc[[1L]], 'adj')

  # K4: m=6, n=4 -> 3 cycles
  t4 <- minimum_spanning_tree(g_k4)
  cyc4 <- fundamental_cycles(g_k4, t4)
  expect_length(cyc4, 3L)
})

test_that('each fundamental cycle has all vertices with degree 0 or 2', {
  t <- minimum_spanning_tree(g_k3)
  cyc <- fundamental_cycles(g_k3, t)
  expect_true(all(vapply(cyc, \(c) all(lengths(c) == 0L | lengths(c) == 2L), logical(1L))))
})

# --- fundamental_cuts ---

test_that('fundamental_cuts returns n - 1 cuts', {
  # K3: n=3 -> 2 cuts
  t <- minimum_spanning_tree(g_k3)
  cuts <- fundamental_cuts(g_k3, t)
  expect_length(cuts, 2L)
  expect_s3_class(cuts[[1L]], 'adj')

  # K4: n=4 -> 3 cuts
  t4 <- minimum_spanning_tree(g_k4)
  cuts4 <- fundamental_cuts(g_k4, t4)
  expect_length(cuts4, 3L)
})

test_that('each fundamental cut contains the corresponding tree edge', {
  t <- minimum_spanning_tree(g_k3)
  cuts <- fundamental_cuts(g_k3, t)
  expect_true(all(vapply(cuts, \(cut) sum(lengths(cut)) %/% 2L > 0L, logical(1L))))
})
