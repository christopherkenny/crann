# count_spanning_trees validates input

    Code
      count_spanning_trees(list(1L, 2L))
    Condition
      Error in `count_spanning_trees()`:
      ! `graph` must be an <adj> object.

---

    Code
      count_spanning_trees(adj::adj(list(integer(0L))))
    Condition
      Error in `count_spanning_trees()`:
      ! `graph` must have at least 2 vertices.

