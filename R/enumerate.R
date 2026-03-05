#' Enumerate all spanning trees
#'
#' Enumerates all spanning trees of a connected undirected graph using
#' Winter's (1986) contraction-based algorithm. The algorithm has worst-case
#' time complexity O(n + m + nt) and space complexity O(n^2), where n is the
#' number of vertices, m the number of edges, and t the number of spanning
#' trees.
#'
#' @param graph An `adj` object representing a connected undirected graph
#'   without self-loops or duplicate edges.
#'
#' @return A list of `adj` objects, one per spanning tree.
#' @export
#' @references Winter, P. (1986). An algorithm for the enumeration of spanning
#'   trees. *BIT Numerical Mathematics*, 26(1), 44--62.
#'   \doi{10.1007/BF01939361}
#'
#' @examples
#' # Triangle: 3 spanning trees
#' g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
#' trees <- enumerate_spanning_trees(g)
#' length(trees)
enumerate_spanning_trees <- function(graph) {
  if (!adj::is_adj(graph)) {
    cli::cli_abort('{.arg graph} must be an {.cls adj} object.')
  }
  n <- length(graph)
  if (n < 2L) {
    cli::cli_abort('{.arg graph} must have at least 2 vertices.')
  }

  count <- count_spanning_trees(graph)
  .Call(enumerate_spanning_trees_c, graph, count)
}

#' Enumerate spanning trees as an edge matrix
#'
#' Returns a compact integer matrix encoding all spanning trees of a
#' connected undirected graph. The matrix has n-1 rows and 2t columns,
#' where n is the number of vertices and t is the number of spanning
#' trees. For spanning tree k (1-indexed), columns 2k-1 and 2k hold the
#' u and v endpoints (1-indexed vertex IDs) of each of the n-1 edges.
#'
#' This function is substantially faster than
#' [enumerate_spanning_trees()] for graphs with many spanning trees
#' because it avoids per-tree R memory allocation: the entire output is
#' a single integer matrix allocation.
#'
#' @param graph An `adj` object representing a connected undirected graph
#'   without self-loops or duplicate edges.
#'
#' @return An integer matrix with n-1 rows and 2t columns.
#' @export
#' @references Winter, P. (1986). An algorithm for the enumeration of
#'   spanning trees. *BIT Numerical Mathematics*, 26(1), 44--62.
#'   \doi{10.1007/BF01939361}
#'
#' @examples
#' # Triangle: 3 spanning trees, 2 edges each -> 2 x 6 matrix
#' g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
#' enumerate_spanning_trees_edges(g)
enumerate_spanning_trees_edges <- function(graph) {
  if (!adj::is_adj(graph)) {
    cli::cli_abort('{.arg graph} must be an {.cls adj} object.')
  }
  n <- length(graph)
  if (n < 2L) {
    cli::cli_abort('{.arg graph} must have at least 2 vertices.')
  }

  count <- count_spanning_trees(graph)
  .Call(enumerate_spanning_trees_matrix_c, graph, count)
}
