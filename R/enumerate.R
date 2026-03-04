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
#' @returns A list of `adj` objects, one per spanning tree.
#'
#' @references Winter, P. (1986). An algorithm for the enumeration of spanning
#'   trees. *BIT Numerical Mathematics*, 26(1), 44--62.
#'   \doi{10.1007/BF01939361}
#'
#' @examples
#' # Triangle: 3 spanning trees
#' g <- adj::adj(list(c(2L, 3L), c(1L, 3L), c(1L, 2L)))
#' trees <- enumerate_spanning_trees(g)
#' length(trees)
#'
#' @export
enumerate_spanning_trees <- function(graph) {
  if (!adj::is_adj(graph)) {
    cli::cli_abort('{.arg graph} must be an {.cls adj} object.')
  }
  n <- length(graph)
  if (n < 2L) {
    cli::cli_abort('{.arg graph} must have at least 2 vertices.')
  }

  # Extract adjacency as a plain list of integer vectors
  nbrs <- lapply(seq_len(n), function(i) graph[[i]])

  # Proper labeling: inv_label[new_label] = original vertex
  inv_label <- label_graph(nbrs, n)
  label <- integer(n)
  for (i in seq_len(n)) label[inv_label[i]] <- i

  # Build edge list in relabeled space: edges[e, ] = c(j, i) with j > i
  edges <- build_edge_list(nbrs, label, n)
  m <- nrow(edges)

  # Initialize mutable state for CONTRACT
  state <- initialize_state(edges, n, m)
  state$inv_label <- inv_label

  # Accumulate spanning trees
  trees_env <- new.env(parent = emptyenv())
  trees_env$trees <- list()

  contract(state, 0L, edges, trees_env)

  trees_env$trees
}

# Proper labeling via greedy BFS from the highest-degree vertex.
# At each step, selects the unlabeled vertex adjacent to a labeled vertex
# with the largest degree in G.
# Returns inv_label: inv_label[new_label] = original vertex.
label_graph <- function(nbrs, n) {
  deg <- lengths(nbrs)
  inv_label <- integer(n)
  labeled <- logical(n)
  frontier_deg <- rep(-1L, n)

  start <- which.max(deg)
  inv_label[1L] <- start
  labeled[start] <- TRUE
  for (v in nbrs[[start]]) {
    frontier_deg[v] <- deg[v]
  }

  for (lbl in 2L:n) {
    best <- which.max(frontier_deg)
    inv_label[lbl] <- best
    labeled[best] <- TRUE
    frontier_deg[best] <- -1L
    for (v in nbrs[[best]]) {
      if (!labeled[v] && frontier_deg[v] == -1L) {
        frontier_deg[v] <- deg[v]
      }
    }
  }

  inv_label
}

# Build edge list in relabeled space.
# Returns a 2-column integer matrix with col1 > col2 (relabeled endpoints).
build_edge_list <- function(nbrs, label, n) {
  rows <- list()
  for (u in seq_len(n)) {
    for (v in nbrs[[u]]) {
      if (u < v) {
        ju <- label[u]
        jv <- label[v]
        rows[[length(rows) + 1L]] <- c(max(ju, jv), min(ju, jv))
      }
    }
  }
  if (length(rows) == 0L) {
    return(matrix(integer(0L), nrow = 0L, ncol = 2L))
  }
  do.call(rbind, rows)
}

# Initialize E, EE, and chosen in a mutable environment.
# E[[j]][[i]]: integer vector of edge IDs between relabeled vertices j and i
#   (j > i, 1-indexed).
# EE[[j]]: decreasing integer vector of i-values with non-empty E[[j]][[i]].
# chosen[k+1]: neighbor of vertex n-k selected at level k.
initialize_state <- function(edges, n, m) {
  state <- new.env(parent = emptyenv())
  state$n <- n

  E <- vector('list', n)
  E[[1L]] <- list()
  for (j in 2L:n) {
    E[[j]] <- vector('list', j - 1L)
    for (i in seq_len(j - 1L)) E[[j]][[i]] <- integer(0L)
  }
  for (eid in seq_len(m)) {
    j <- edges[eid, 1L]
    i <- edges[eid, 2L]
    E[[j]][[i]] <- c(E[[j]][[i]], eid)
  }
  state$E <- E

  EE <- vector('list', n)
  EE[[1L]] <- integer(0L)
  for (j in 2L:n) {
    ee <- integer(0L)
    for (i in seq_len(j - 1L)) {
      if (length(E[[j]][[i]]) > 0L) ee <- c(ee, i)
    }
    EE[[j]] <- sort(ee, decreasing = TRUE)
  }
  state$EE <- EE

  state$chosen <- integer(n - 1L)
  state
}

# Recursive CONTRACT procedure. k is the current depth (0-indexed);
# processes vertex nk = n - k.
contract <- function(state, k, edges, trees_env) {
  nk <- state$n - k
  EE_nk <- state$EE[[nk]]

  for (r in EE_nk) {
    state$chosen[k + 1L] <- r

    if (nk == 2L) {
      output_trees(state, edges, trees_env)
    } else {
      # Contract vertex nk into r: merge E[[nk]][[i]] into E[[r]][[i]] for i < r
      undo <- list()
      to_merge <- EE_nk[EE_nk < r]

      for (i in to_merge) {
        old_len <- length(state$E[[r]][[i]])
        state$E[[r]][[i]] <- c(state$E[[r]][[i]], state$E[[nk]][[i]])
        if (old_len == 0L) {
          state$EE[[r]] <- sort(c(state$EE[[r]], i), decreasing = TRUE)
          undo[[length(undo) + 1L]] <- list(type = 'create', r = r, i = i)
        } else {
          undo[[length(undo) + 1L]] <- list(
            type = 'extend', r = r, i = i, len = old_len
          )
        }
      }

      contract(state, k + 1L, edges, trees_env)

      for (u in rev(undo)) {
        if (u$type == 'create') {
          state$E[[u$r]][[u$i]] <- integer(0L)
          state$EE[[u$r]] <- state$EE[[u$r]][state$EE[[u$r]] != u$i]
        } else {
          state$E[[u$r]][[u$i]] <- state$E[[u$r]][[u$i]][seq_len(u$len)]
        }
      }
    }
  }
}

# Called at the base case (nk = 2). Enumerates all spanning trees in the
# current partition as the Cartesian product of the chosen edge sets.
output_trees <- function(state, edges, trees_env) {
  n <- state$n
  edge_sets <- vector('list', n - 1L)
  for (k in 0L:(n - 2L)) {
    nk <- n - k
    r <- state$chosen[k + 1L]
    edge_sets[[k + 1L]] <- state$E[[nk]][[r]]
  }
  expand_product(edge_sets, 1L, integer(n - 1L), edges, n, state$inv_label, trees_env)
}

# Recursively expands the Cartesian product of edge_sets.
# Each leaf (fully selected combination) is converted to an adj spanning tree.
expand_product <- function(edge_sets, level, selected, edges, n, inv_label, trees_env) {
  if (level > length(edge_sets)) {
    tree <- build_spanning_tree_adj(selected, edges, n, inv_label)
    idx <- length(trees_env$trees) + 1L
    trees_env$trees[[idx]] <- tree
    return(invisible(NULL))
  }
  for (eid in edge_sets[[level]]) {
    selected[level] <- eid
    expand_product(edge_sets, level + 1L, selected, edges, n, inv_label, trees_env)
  }
}

# Builds an adj object for a spanning tree given a vector of edge IDs in
# the relabeled space.
build_spanning_tree_adj <- function(edge_ids, edges, n, inv_label) {
  nbrs <- vector('list', n)
  for (i in seq_len(n)) nbrs[[i]] <- integer(0L)

  for (eid in edge_ids) {
    rel_j <- edges[eid, 1L]
    rel_i <- edges[eid, 2L]
    orig_u <- inv_label[rel_j]
    orig_v <- inv_label[rel_i]
    nbrs[[orig_u]] <- c(nbrs[[orig_u]], orig_v)
    nbrs[[orig_v]] <- c(nbrs[[orig_v]], orig_u)
  }

  adj::adj(nbrs, self_loops = 'error', duplicates = 'error')
}
