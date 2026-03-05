#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <string.h>
#include <stdint.h>

/* Triangular index for (j, i) with j > i >= 1 (1-indexed). */
static inline int tri(int j, int i) {
    return (j - 1) * (j - 2) / 2 + (i - 1);
}

typedef struct {
    int r, i, old_len;
} UndoEntry;

typedef struct {
    int n, m;
    /* E_data[tri(j,i)*(m+1)+pos]: 1-indexed edge ID for pair (j>i) */
    int *E_data;
    int *E_len;      /* current length of E[tri(j,i)] */
    /* EE_bits[j]: bit i set iff vertex i is active in EE[j] (1-indexed, j=1..n, i=1..j-1).
     * Supports n <= 63 (vertex IDs fit in bits 1..63 of uint64_t). */
    uint64_t *EE_bits;
    int *chosen;     /* chosen[k] = r at depth k (0-indexed k, 1-indexed r) */
    UndoEntry *undo;
    int undo_top;
    /* Output */
    SEXP result;     /* pre-allocated VECSXP(total_trees) */
    int n_trees;
    /* Shared objects for adj construction (allocated once) */
    SEXP cls, dup_str, loop_str;
    SEXP dup_sym, loop_sym;
    /* Reusable scratch buffers for adj construction */
    int *tmp_deg, *tmp_off;
    int *selected;   /* [n-1]: current edge IDs being expanded */
    /* Edge list in original vertex space (0-indexed): orig_edges[e*2+0/1] */
    int *orig_edges;
    /* Edge list in relabeled space (1-indexed): edges[e*2+0]=j, edges[e*2+1]=i, j>i */
    int *edges;
} EnumState;

/* Build one adj spanning tree from selected[0..n-2] (1-indexed edge IDs). */
static SEXP build_tree_adj(EnumState *s) {
    int n = s->n;
    int n1 = n - 1;

    memset(s->tmp_deg, 0, n * sizeof(int));
    for (int k = 0; k < n1; k++) {
        int e = s->selected[k] - 1;
        s->tmp_deg[s->orig_edges[e * 2 + 0]]++;
        s->tmp_deg[s->orig_edges[e * 2 + 1]]++;
    }

    SEXP tree = PROTECT(Rf_allocVector(VECSXP, n));
    for (int v = 0; v < n; v++) {
        /* Safe: SET_VECTOR_ELT stores immediately; no R allocation occurs between
         * Rf_allocVector and SET_VECTOR_ELT, so GC cannot collect the INTSXP. */
        SET_VECTOR_ELT(tree, v, Rf_allocVector(INTSXP, s->tmp_deg[v]));
        s->tmp_off[v] = 0;
    }
    for (int k = 0; k < n1; k++) {
        int e = s->selected[k] - 1;
        int oj = s->orig_edges[e * 2 + 0];
        int oi = s->orig_edges[e * 2 + 1];
        INTEGER(VECTOR_ELT(tree, oj))[s->tmp_off[oj]++] = oi + 1; /* 1-indexed for R */
        INTEGER(VECTOR_ELT(tree, oi))[s->tmp_off[oi]++] = oj + 1;
    }
    Rf_setAttrib(tree, R_ClassSymbol, s->cls);
    Rf_setAttrib(tree, s->dup_sym,    s->dup_str);
    Rf_setAttrib(tree, s->loop_sym,   s->loop_str);
    UNPROTECT(1);
    return tree;
}

/* Recursively expand the Cartesian product of the edge sets chosen so far.
 * At each level, the edge set is E[tri(n-level, chosen[level])]. */
static void expand_product(EnumState *s, int level) {
    int n1 = s->n - 1;
    if (level == n1) {
        SEXP tree = build_tree_adj(s);
        SET_VECTOR_ELT(s->result, s->n_trees++, tree);
        return;
    }
    int nk   = s->n - level;
    int r    = s->chosen[level];
    int pair = tri(nk, r);
    int len  = s->E_len[pair];
    int *eids = s->E_data + pair * (s->m + 1);
    for (int ei = 0; ei < len; ei++) {
        s->selected[level] = eids[ei];
        expand_product(s, level + 1);
    }
}

/* Recursive CONTRACT procedure at depth k (0-indexed), processing vertex nk = n - k.
 *
 * EE_bits[nk] encodes the active neighbors of nk (i < nk) as a bitmask.
 * We iterate r from the highest bit down.  After extracting r, the remaining
 * bits in `remaining` are exactly {i in EE_bits[nk] : i < r} — which is the
 * "to_merge" set for this choice of r.  This avoids any sorted array or memmove. */
static void contract(EnumState *s, int k) {
    int nk = s->n - k;
    uint64_t remaining = s->EE_bits[nk];

    while (remaining) {
        /* Largest active neighbor becomes r */
        int r = 63 - __builtin_clzll(remaining);
        remaining &= ~(1ULL << r);
        /* After removing r, `remaining` == to_merge == {i in EE_bits[nk] : i < r} */

        s->chosen[k] = r;

        if (nk == 2) {
            expand_product(s, 0);
        } else {
            int undo_start = s->undo_top;
            uint64_t to_merge = remaining;

            while (to_merge) {
                int i = 63 - __builtin_clzll(to_merge);
                to_merge &= ~(1ULL << i);

                int src_pair = tri(nk, i);
                int dst_pair = tri(r,  i);
                int old_len  = s->E_len[dst_pair];
                int src_len  = s->E_len[src_pair];

                memcpy(
                    s->E_data + dst_pair * (s->m + 1) + old_len,
                    s->E_data + src_pair * (s->m + 1),
                    src_len * sizeof(int)
                );
                s->E_len[dst_pair] = old_len + src_len;

                if (old_len == 0) {
                    s->EE_bits[r] |= (1ULL << i); /* O(1) insert */
                }

                s->undo[s->undo_top].r       = r;
                s->undo[s->undo_top].i       = i;
                s->undo[s->undo_top].old_len = old_len;
                s->undo_top++;
            }

            contract(s, k + 1);

            /* Restore in reverse */
            for (int ui = s->undo_top - 1; ui >= undo_start; ui--) {
                UndoEntry u = s->undo[ui];
                if (u.old_len == 0) {
                    s->EE_bits[u.r] &= ~(1ULL << u.i); /* O(1) remove */
                }
                s->E_len[tri(u.r, u.i)] = u.old_len;
            }
            s->undo_top = undo_start;
        }
    }
}

/* Main entry point.
 * graph_R: adj object (plain R list of integer vectors, 1-indexed neighbors).
 * count_R: expected number of spanning trees (numeric scalar from Kirchhoff). */
SEXP enumerate_spanning_trees_c(SEXP graph_R, SEXP count_R) {
    int n = Rf_length(graph_R);

    if (n > 63) {
        Rf_error(
            "enumerate_spanning_trees: graphs with more than 63 vertices are "
            "not supported (would require more spanning trees than can be stored)"
        );
    }

    int total_trees = (int)Rf_asReal(count_R);
    if (total_trees == 0) return Rf_allocVector(VECSXP, 0);

    /* ---- Step 1: Proper labeling (BFS from max-degree vertex) ---- */
    int *deg          = (int *)R_alloc(n, sizeof(int));
    int *inv_label    = (int *)R_alloc(n, sizeof(int));
    int *label        = (int *)R_alloc(n, sizeof(int));
    int *labeled      = (int *)R_alloc(n, sizeof(int));
    int *frontier_deg = (int *)R_alloc(n, sizeof(int));

    for (int v = 0; v < n; v++) {
        deg[v] = Rf_length(VECTOR_ELT(graph_R, v));
    }
    memset(labeled, 0, n * sizeof(int));
    for (int v = 0; v < n; v++) frontier_deg[v] = -1;

    int start = 0;
    for (int v = 1; v < n; v++) {
        if (deg[v] > deg[start]) start = v;
    }
    inv_label[0] = start;
    labeled[start] = 1;
    {
        SEXP nbrs = VECTOR_ELT(graph_R, start);
        int *arr = INTEGER(nbrs), d = Rf_length(nbrs);
        for (int j = 0; j < d; j++) frontier_deg[arr[j] - 1] = deg[arr[j] - 1];
    }
    for (int lbl = 1; lbl < n; lbl++) {
        int best = -1;
        for (int v = 0; v < n; v++) {
            if (frontier_deg[v] >= 0 && (best < 0 || frontier_deg[v] > frontier_deg[best]))
                best = v;
        }
        inv_label[lbl] = best;
        labeled[best]  = 1;
        frontier_deg[best] = -1;
        SEXP nbrs = VECTOR_ELT(graph_R, best);
        int *arr = INTEGER(nbrs), d = Rf_length(nbrs);
        for (int j = 0; j < d; j++) {
            int v = arr[j] - 1;
            if (!labeled[v] && frontier_deg[v] == -1)
                frontier_deg[v] = deg[v];
        }
    }
    for (int lbl = 0; lbl < n; lbl++) label[inv_label[lbl]] = lbl + 1;

    /* ---- Step 2: Build edge lists ---- */
    int m = 0;
    for (int u = 0; u < n; u++) {
        SEXP nbrs = VECTOR_ELT(graph_R, u);
        int *arr = INTEGER(nbrs), d = Rf_length(nbrs);
        for (int k = 0; k < d; k++) {
            if (u < arr[k] - 1) m++;
        }
    }

    /* Relabeled edge list (1-indexed): edges[e*2+0]=j, edges[e*2+1]=i, j>i */
    int *edges = (int *)R_alloc(m * 2, sizeof(int));
    /* Original edge list (0-indexed): orig_edges[e*2+0/1] = original vertex */
    int *orig_edges = (int *)R_alloc(m * 2, sizeof(int));

    int eid = 0;
    for (int u = 0; u < n; u++) {
        SEXP nbrs = VECTOR_ELT(graph_R, u);
        int *arr = INTEGER(nbrs), d = Rf_length(nbrs);
        for (int k = 0; k < d; k++) {
            int v = arr[k] - 1;
            if (u < v) {
                int lu = label[u], lv = label[v];
                edges[eid * 2 + 0] = (lu > lv) ? lu : lv;
                edges[eid * 2 + 1] = (lu > lv) ? lv : lu;
                orig_edges[eid * 2 + 0] = inv_label[edges[eid * 2 + 0] - 1];
                orig_edges[eid * 2 + 1] = inv_label[edges[eid * 2 + 1] - 1];
                eid++;
            }
        }
    }

    /* ---- Step 3: Initialize state ---- */
    int n_pairs = n * (n - 1) / 2;

    EnumState s;
    s.n          = n;
    s.m          = m;
    s.edges      = edges;
    s.orig_edges = orig_edges;

    s.E_data  = (int *)R_alloc((size_t)n_pairs * (m + 1), sizeof(int));
    s.E_len   = (int *)R_alloc(n_pairs, sizeof(int));
    s.EE_bits = (uint64_t *)R_alloc(n + 1, sizeof(uint64_t));
    s.chosen  = (int *)R_alloc(n, sizeof(int));
    s.undo    = (UndoEntry *)R_alloc((size_t)(m + 1) * n, sizeof(UndoEntry));
    s.selected  = (int *)R_alloc(n - 1, sizeof(int));
    s.tmp_deg   = (int *)R_alloc(n, sizeof(int));
    s.tmp_off   = (int *)R_alloc(n, sizeof(int));

    memset(s.E_data,  0, (size_t)n_pairs * (m + 1) * sizeof(int));
    memset(s.E_len,   0, n_pairs * sizeof(int));
    memset(s.EE_bits, 0, (n + 1) * sizeof(uint64_t));

    for (int e = 0; e < m; e++) {
        int j = edges[e * 2 + 0], i = edges[e * 2 + 1];
        int p = tri(j, i);
        s.E_data[p * (m + 1) + s.E_len[p]] = e + 1;
        s.E_len[p]++;
    }
    for (int j = 2; j <= n; j++) {
        for (int i = 1; i < j; i++) {
            if (s.E_len[tri(j, i)] > 0) s.EE_bits[j] |= (1ULL << i);
        }
    }

    /* ---- Step 4: Shared adj attribute objects ---- */
    SEXP result   = PROTECT(Rf_allocVector(VECSXP, total_trees));
    SEXP cls      = PROTECT(Rf_allocVector(STRSXP, 2));
    SEXP dup_str  = PROTECT(Rf_mkString("error"));
    SEXP loop_str = PROTECT(Rf_mkString("error"));
    SET_STRING_ELT(cls, 0, Rf_mkChar("adj"));
    SET_STRING_ELT(cls, 1, Rf_mkChar("list"));

    s.result   = result;
    s.n_trees  = 0;
    s.undo_top = 0;
    s.cls      = cls;
    s.dup_str  = dup_str;
    s.loop_str = loop_str;
    s.dup_sym  = Rf_install("duplicates");
    s.loop_sym = Rf_install("self_loops");

    /* ---- Step 5: Single-pass enumeration ---- */
    contract(&s, 0);

    UNPROTECT(4); /* result, cls, dup_str, loop_str */
    return result;
}
