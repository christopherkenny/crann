# sample_spanning_tree validates input

    Code
      sample_spanning_tree(list(c(2L), c(1L)))
    Condition
      Error in `sample_spanning_tree()`:
      ! `graph` must be an <adj> object.

---

    Code
      sample_spanning_tree(adj::adj(list(integer(0L))))
    Condition
      Error in `sample_spanning_tree()`:
      ! `graph` must have at least 2 vertices.

