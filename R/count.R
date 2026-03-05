#' Count spanning trees
#'
#' Counts the number of spanning trees of a connected undirected graph using
#' Kirchhoff's matrix tree theorem: the count equals the determinant of any
#' (n-1) x (n-1) cofactor of the graph Laplacian.
#'
#' @param graph An `adj` object representing a connected undirected graph.
#'
#' @return A `numeric` scalar. (Integer-valued but returned as `numeric` since
#'   counts can exceed `.Machine$integer.max` for dense graphs.)
#' @export
#' @seealso [enumerate_spanning_trees()] to list all spanning trees.
#'
#' @examples
#' # Triangle: 3 spanning trees
#' g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
#' count_spanning_trees(g)
count_spanning_trees <- function(graph) {
  if (!adj::is_adj(graph)) {
    cli::cli_abort('{.arg graph} must be an {.cls adj} object.')
  }
  if (length(graph) < 2L) {
    cli::cli_abort('{.arg graph} must have at least 2 vertices.')
  }
  L <- adj::adj_laplacian(graph, sparse = FALSE)
  round(det(L[-1L, -1L, drop = FALSE]))
}
