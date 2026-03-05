#' Sample a uniform random spanning tree
#'
#' Samples a spanning tree uniformly at random from the set of all spanning
#' trees using Wilson's (1996) loop-erased random walk algorithm.
#'
#' @param graph An `adj` object representing a connected undirected graph.
#'
#' @return An `adj` object representing a spanning tree of `graph`.
#' @export
#' @references
#' Wilson, D.B. (1996). Generating random spanning trees more quickly than
#' the cover time. *Proceedings of the 28th Annual ACM Symposium on Theory
#' of Computing*, 296–303. \doi{10.1145/237814.237880}
#'
#' @seealso [enumerate_spanning_trees()], [minimum_spanning_tree()]
#'
#' @examples
#' set.seed(1)
#' g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
#' sample_spanning_tree(g)
sample_spanning_tree <- function(graph) {
  if (!adj::is_adj(graph)) {
    cli::cli_abort('{.arg graph} must be an {.cls adj} object.')
  }
  n <- length(graph)
  if (n < 2L) {
    cli::cli_abort('{.arg graph} must have at least 2 vertices.')
  }

  in_tree <- logical(n)
  next_node <- integer(n)

  # Root vertex 1 starts in the tree
  in_tree[1L] <- TRUE

  tree_nbrs <- vector('list', n)
  for (i in seq_len(n)) tree_nbrs[[i]] <- integer(0L)

  for (i in seq_len(n)) {
    if (in_tree[i]) {
      next
    }

    # Random walk from i until hitting the tree.
    # next_node[v] is overwritten on revisits, implicitly erasing loops.
    v <- i
    while (!in_tree[v]) {
      nbrs_v <- graph[[v]]
      next_node[v] <- nbrs_v[sample.int(length(nbrs_v), 1L)]
      v <- next_node[v]
    }

    # Trace back, adding the loop-erased path to the tree
    v <- i
    while (!in_tree[v]) {
      w <- next_node[v]
      tree_nbrs[[v]] <- c(tree_nbrs[[v]], w)
      tree_nbrs[[w]] <- c(tree_nbrs[[w]], v)
      in_tree[v] <- TRUE
      v <- w
    }
  }

  adj::adj(tree_nbrs, self_loops = 'error', duplicates = 'error')
}
