# minimum_spanning_tree validates input

    Code
      minimum_spanning_tree(list(1L, 2L))
    Condition
      Error in `minimum_spanning_tree()`:
      ! `graph` must be an <adj> object.

---

    Code
      minimum_spanning_tree(g, weights = c(1, 2))
    Condition
      Error in `minimum_spanning_tree()`:
      ! `weights` must have length 3 (the number of edges), not 2.

