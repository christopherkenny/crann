#!/usr/bin/env Rscript
library(glue)

set.seed(42)

W <- 400L
H <- 400L

edges <- vector('list', 40000L)
nodes <- vector('list', 40000L)
n_edges <- 0L
n_nodes <- 0L

push_edge <- function(x1, y1, x2, y2, lw) {
  n_edges <<- n_edges + 1L
  edges[[n_edges]] <<- c(x1, y1, x2, y2, lw)
}

push_node <- function(x, y, r) {
  n_nodes <<- n_nodes + 1L
  nodes[[n_nodes]] <<- c(x, y, r)
}

branch <- function(x, y, angle, len, depth) {
  push_node(x, y, r = 1.0 + depth * 0.25)
  if (len < 3.5 || depth <= 0L) {
    return(invisible(NULL))
  }

  angle <- angle + rnorm(1, 0, 0.055)
  x2 <- x + sin(angle) * len
  y2 <- y - cos(angle) * len

  push_edge(x, y, x2, y2, max(0.3, (depth / 8) * 3.2))

  n_sub <- sample(c(2L, 2L, 3L), 1L)
  spread <- (pi / 3) * (1.25 - 0.35 * ((7 - depth) / 7))
  offsets <- seq(-spread / 2, spread / 2, length.out = n_sub) + runif(n_sub, -0.06, 0.06)

  lapply(offsets, function(da) {
    mul <- 0.80 * (1 - 0.07 * abs(da) / (spread / 2))
    droop <- if (depth <= 3L && abs(da) > spread / 3) runif(1, 0.08, 0.25) * sign(da) else 0
    branch(x2, y2, angle + da + droop, len * mul + runif(1, -1.5, 1.5), depth - 1L)
  })
  invisible(NULL)
}

trunk_base_x <- W / 2
trunk_base_y <- H - 25
trunk_top_x <- trunk_base_x + rnorm(1, 0, 3)
trunk_top_y <- trunk_base_y - 52

push_edge(trunk_base_x, trunk_base_y, trunk_top_x, trunk_top_y, lw = 12.0)
push_node(trunk_top_x, trunk_top_y, r = 6.0)

n_main <- 5L
main_angles <- seq(-pi / 2.8, pi / 2.8, length.out = n_main) + runif(n_main, -0.04, 0.04)
main_lens <- 15 + runif(n_main, -2, 2)

lapply(seq_len(n_main), \(i) branch(trunk_top_x, trunk_top_y, main_angles[i], main_lens[i], depth = 8L))

edge_mat <- do.call(rbind, edges[seq_len(n_edges)])
node_mat <- do.call(rbind, nodes[seq_len(n_nodes)])
colnames(edge_mat) <- c('x1', 'y1', 'x2', 'y2', 'lw')
colnames(node_mat) <- c('x', 'y', 'r')

edge_df <- as.data.frame(edge_mat)
node_df <- as.data.frame(node_mat)
node_df$key <- paste0(round(node_df$x), ',', round(node_df$y))
node_df <- node_df[!duplicated(node_df$key), ]

dark_green <- '#1D3A20'
bg_color <- '#FAFAF7'
pad <- 20
vx <- floor(min(c(edge_df$x1, edge_df$x2, node_df$x))) - pad
vy <- floor(min(c(edge_df$y1, edge_df$y2, node_df$y))) - pad
vw <- ceiling(max(c(edge_df$x1, edge_df$x2, node_df$x))) - vx + pad
vh <- ceiling(max(c(edge_df$y1, edge_df$y2, node_df$y))) - vy + pad

svg_out <- c(
  glue('<svg xmlns="http://www.w3.org/2000/svg" width="{vw}" height="{vh}" viewBox="{vx} {vy} {vw} {vh}">'),
  glue('<rect x="{vx}" y="{vy}" width="{vw}" height="{vh}" fill="{bg_color}"/>'),
  '<g stroke-linecap="round" stroke-linejoin="round">',
  with(edge_df, glue('  <line x1="{round(x1,2)}" y1="{round(y1,2)}" x2="{round(x2,2)}" y2="{round(y2,2)}" stroke="{dark_green}" stroke-width="{round(lw,2)}"/>')),
  with(node_df, glue('  <circle cx="{round(x,2)}" cy="{round(y,2)}" r="{round(r,2)}" fill="{dark_green}"/>')),
  '</g>',
  '</svg>'
)

dir.create('man/figures', showWarnings = FALSE, recursive = TRUE)
svg_path <- 'data-raw/logo_tree.svg'
png_path <- 'data-raw/logo_tree.png'
writeLines(svg_out, svg_path)
rsvg::rsvg_png(svg_path, png_path, width = 1200)
