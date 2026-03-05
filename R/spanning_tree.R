#' Test if a graph is a spanning tree
#'
#' Returns `TRUE` if `tree` is a spanning tree: a connected acyclic graph with
#' exactly n-1 edges. To additionally check that `tree` uses only edges from a
#' reference graph, see [is_spanning_tree_of()].
#'
#' @param tree An `adj` object to test.
#'
#' @returns A logical scalar.
#' @export
#' @seealso [is_spanning_tree_of()], [minimum_spanning_tree()],
#'   [enumerate_spanning_trees()]
#'
#' @examples
#' g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
#' t <- minimum_spanning_tree(g)
#' is_spanning_tree(t)
is_spanning_tree <- function(tree) {
  if (!adj::is_adj(tree)) {
    return(FALSE)
  }
  n <- length(tree)
  if (sum(lengths(tree)) %/% 2L != n - 1L) {
    return(FALSE)
  }

  # Connectivity via BFS from vertex 1
  visited <- logical(n)
  visited[1L] <- TRUE
  queue <- 1L
  while (length(queue) > 0L) {
    curr <- queue[1L]
    queue <- queue[-1L]
    for (nb in tree[[curr]]) {
      if (!visited[nb]) {
        visited[nb] <- TRUE
        queue <- c(queue, nb)
      }
    }
  }
  all(visited)
}

#' Test if a graph is a spanning tree of another graph
#'
#' Returns `TRUE` if `tree` is a spanning tree of `graph`: a connected acyclic
#' subgraph that spans all vertices and uses only edges present in `graph`.
#'
#' @param tree An `adj` object to test.
#' @param graph An `adj` object representing a connected undirected graph.
#'
#' @returns A logical scalar.
#' @export
#' @seealso [is_spanning_tree()], [minimum_spanning_tree()],
#'   [enumerate_spanning_trees()]
#'
#' @examples
#' g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
#' t <- minimum_spanning_tree(g)
#' is_spanning_tree_of(t, g)
is_spanning_tree_of <- function(tree, graph) {
  if (!adj::is_adj(graph)) {
    return(FALSE)
  }
  if (!is_spanning_tree(tree)) {
    return(FALSE)
  }
  n <- length(graph)
  if (length(tree) != n) {
    return(FALSE)
  }

  # All tree edges must exist in graph
  for (u in seq_len(n)) {
    g_nbrs <- graph[[u]]
    for (v in tree[[u]]) {
      if (!(v %in% g_nbrs)) {
        return(FALSE)
      }
    }
  }
  TRUE
}

#' Fundamental cycles of a spanning tree
#'
#' Returns the fundamental cycles of a spanning tree with respect to the
#' original graph. There is one fundamental cycle per non-tree edge
#' (m - n + 1 total), formed by adding that edge to the unique path between
#' its endpoints in the spanning tree.
#'
#' @param graph An `adj` object representing a connected undirected graph.
#' @param tree An `adj` object representing a spanning tree of `graph`.
#'
#' @return A list of `adj` objects, one per non-tree edge. Each `adj`
#'   represents the cycle as a subgraph of `graph`.
#' @export
#' @seealso [fundamental_cuts()]
#'
#' @examples
#' g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
#' t <- minimum_spanning_tree(g)
#' fundamental_cycles(g, t)
fundamental_cycles <- function(graph, tree) {
  if (!adj::is_adj(graph)) {
    cli::cli_abort('{.arg graph} must be an {.cls adj} object.')
  }
  if (!adj::is_adj(tree)) {
    cli::cli_abort('{.arg tree} must be an {.cls adj} object.')
  }
  n <- length(graph)

  cycles <- list()
  for (u in seq_len(n)) {
    for (v in graph[[u]]) {
      if (u < v && !(v %in% tree[[u]])) {
        path <- tree_path(tree, u, v, n)
        cycles[[length(cycles) + 1L]] <- cycle_adj(path, n)
      }
    }
  }
  cycles
}

#' Fundamental cuts of a spanning tree
#'
#' Returns the fundamental cuts of a spanning tree with respect to the original
#' graph. There is one fundamental cut per tree edge (n - 1 total), consisting
#' of all edges in the graph that cross the bipartition induced by removing that
#' tree edge.
#'
#' @param graph An `adj` object representing a connected undirected graph.
#' @param tree An `adj` object representing a spanning tree of `graph`.
#'
#' @return A list of `adj` objects, one per tree edge. Each `adj` represents
#'   the cut as a subgraph of `graph`.
#' @export
#' @seealso [fundamental_cycles()]
#'
#' @examples
#' g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
#' t <- minimum_spanning_tree(g)
#' fundamental_cuts(g, t)
fundamental_cuts <- function(graph, tree) {
  if (!adj::is_adj(graph)) {
    cli::cli_abort('{.arg graph} must be an {.cls adj} object.')
  }
  if (!adj::is_adj(tree)) {
    cli::cli_abort('{.arg tree} must be an {.cls adj} object.')
  }
  n <- length(graph)

  cuts <- list()
  for (u in seq_len(n)) {
    for (v in tree[[u]]) {
      if (u < v) {
        comp <- tree_component(tree, u, u, v, n)
        cuts[[length(cuts) + 1L]] <- cut_adj(graph, comp, n)
      }
    }
  }
  cuts
}

# BFS in tree from 'from' to 'to'. Returns integer vector of vertex indices
# along the path (inclusive of both endpoints).
tree_path <- function(tree, from, to, n) {
  parent <- integer(n)
  parent[from] <- -1L
  visited <- logical(n)
  visited[from] <- TRUE
  queue <- from
  while (length(queue) > 0L) {
    curr <- queue[1L]
    queue <- queue[-1L]
    if (curr == to) break
    for (nb in tree[[curr]]) {
      if (!visited[nb]) {
        visited[nb] <- TRUE
        parent[nb] <- curr
        queue <- c(queue, nb)
      }
    }
  }
  path <- to
  while (parent[path[1L]] != -1L) {
    path <- c(parent[path[1L]], path)
  }
  path
}

# Build an adj object for the cycle formed by closing path[1] -> ... -> path[k]
# back to path[1].
cycle_adj <- function(path, n) {
  nbrs <- vector('list', n)
  for (i in seq_len(n)) nbrs[[i]] <- integer(0L)
  k <- length(path)
  for (i in seq_len(k - 1L)) {
    u <- path[i]
    v <- path[i + 1L]
    nbrs[[u]] <- c(nbrs[[u]], v)
    nbrs[[v]] <- c(nbrs[[v]], u)
  }
  # Close the cycle
  nbrs[[path[k]]] <- c(nbrs[[path[k]]], path[1L])
  nbrs[[path[1L]]] <- c(nbrs[[path[1L]]], path[k])
  adj::adj(nbrs, self_loops = 'error', duplicates = 'error')
}

# BFS in tree from 'start' to find its connected component when edge
# (excl_from, excl_to) is removed. Returns logical vector of membership.
tree_component <- function(tree, start, excl_from, excl_to, n) {
  visited <- logical(n)
  visited[start] <- TRUE
  queue <- start
  while (length(queue) > 0L) {
    curr <- queue[1L]
    queue <- queue[-1L]
    for (nb in tree[[curr]]) {
      if (!visited[nb]) {
        if ((curr == excl_from && nb == excl_to) ||
          (curr == excl_to && nb == excl_from)) {
          next
        }
        visited[nb] <- TRUE
        queue <- c(queue, nb)
      }
    }
  }
  visited
}

# Build an adj object for the cut: all graph edges with exactly one endpoint
# in component 'comp' (a logical vector of vertex membership).
cut_adj <- function(graph, comp, n) {
  nbrs <- vector('list', n)
  for (i in seq_len(n)) nbrs[[i]] <- integer(0L)
  for (u in which(comp)) {
    for (v in graph[[u]]) {
      if (!comp[v]) {
        nbrs[[u]] <- c(nbrs[[u]], v)
        nbrs[[v]] <- c(nbrs[[v]], u)
      }
    }
  }
  adj::adj(nbrs, self_loops = 'error', duplicates = 'error')
}
