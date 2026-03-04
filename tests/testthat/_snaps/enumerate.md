# graph input validation works

    Code
      enumerate_spanning_trees(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
    Condition
      Error in `enumerate_spanning_trees()`:
      ! `graph` must be an <adj> object.

---

    Code
      enumerate_spanning_trees(adj::adj(list(integer(0L))))
    Condition
      Error in `enumerate_spanning_trees()`:
      ! `graph` must have at least 2 vertices.

