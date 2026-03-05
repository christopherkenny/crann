#' Minimum spanning tree
#'
#' Finds a minimum spanning tree of a connected undirected graph using
#' Kruskal's algorithm. When `weights` is `NULL` (the default), all edges are
#' treated as having equal weight and any spanning tree is returned.
#'
#' @param graph An `adj` object representing a connected undirected graph.
#' @param weights A numeric vector of edge weights, one per edge. Edges are
#'   ordered by iterating vertices `u = 1, ..., n` and for each `u` iterating
#'   over `graph[[u]]` retaining only neighbors `v > u`. Pass `NULL` for
#'   uniform weights.
#'
#' @return An `adj` object representing the minimum spanning tree.
#' @export
#' @seealso [is_spanning_tree()] to validate a spanning tree.
#'
#' @examples
#' g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
#' minimum_spanning_tree(g)
minimum_spanning_tree <- function(graph, weights = NULL) {
  if (!adj::is_adj(graph)) {
    cli::cli_abort('{.arg graph} must be an {.cls adj} object.')
  }
  n <- length(graph)
  if (n < 2L) {
    cli::cli_abort('{.arg graph} must have at least 2 vertices.')
  }

  nbrs <- lapply(seq_len(n), function(i) graph[[i]])
  edges <- mst_edges(nbrs, n)
  m <- nrow(edges)

  if (is.null(weights)) {
    weights <- rep(1, m)
  } else if (length(weights) != m) {
    cli::cli_abort(
      '{.arg weights} must have length {m} (the number of edges), not {length(weights)}.'
    )
  }

  ord <- order(weights)
  parent <- seq_len(n)
  rnk <- integer(n)
  tree_nbrs <- vector('list', n)
  for (i in seq_len(n)) tree_nbrs[[i]] <- integer(0L)
  added <- 0L

  for (idx in ord) {
    u <- edges[idx, 1L]
    v <- edges[idx, 2L]
    ru <- uf_find(parent, u)
    rv <- uf_find(parent, v)
    if (ru != rv) {
      parent <- uf_union(parent, rnk, ru, rv)
      rnk <- attr(parent, 'rank')
      tree_nbrs[[u]] <- c(tree_nbrs[[u]], v)
      tree_nbrs[[v]] <- c(tree_nbrs[[v]], u)
      added <- added + 1L
      if (added == n - 1L) break
    }
  }

  adj::adj(tree_nbrs, self_loops = 'error', duplicates = 'error')
}

# Returns a 2-column integer matrix of edges (u, v) with u < v, in the order
# used by the weights argument: u = 1..n, v in graph[[u]] with v > u.
mst_edges <- function(nbrs, n) {
  rows <- list()
  for (u in seq_len(n)) {
    for (v in nbrs[[u]]) {
      if (u < v) rows[[length(rows) + 1L]] <- c(u, v)
    }
  }
  if (length(rows) == 0L) {
    return(matrix(integer(0L), nrow = 0L, ncol = 2L))
  }
  do.call(rbind, rows)
}

# Path-compressed union-find: returns root of i.
uf_find <- function(parent, i) {
  while (parent[i] != i) {
    parent[i] <- parent[parent[i]] # path halving
    i <- parent[i]
  }
  i
}

# Union by rank. Returns updated parent vector with a 'rank' attribute.
uf_union <- function(parent, rnk, ru, rv) {
  if (rnk[ru] < rnk[rv]) {
    parent[ru] <- rv
  } else if (rnk[ru] > rnk[rv]) {
    parent[rv] <- ru
  } else {
    parent[rv] <- ru
    rnk[ru] <- rnk[ru] + 1L
  }
  attr(parent, 'rank') <- rnk
  parent
}
