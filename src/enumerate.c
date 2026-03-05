#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <string.h>

/* Triangular index for (j, i) with j > i >= 1 (1-indexed).
 * Returns 0-indexed position: tri(2,1)=0, tri(3,1)=1, tri(3,2)=2, ...
 */
static inline int tri(int j, int i) {
    return (j - 1) * (j - 2) / 2 + (i - 1);
}

typedef struct {
    int r, i, old_len;
} UndoEntry;

typedef struct {
    int n, m, n_pairs;
    /* E_data[tri(j,i) * (m+1) + pos]: edge ID (1-indexed) for pair (j>i, both 1-indexed) */
    int *E_data;
    int *E_len;   /* [n_pairs]: current length of E[tri(j,i)] */
    /* EE_data[(j-1)*n + pos]: active i-value (sorted descending) for vertex j */
    int *EE_data;
    int *EE_len;  /* [n+1]: EE_len[j] = # active i-values for vertex j (1-indexed j) */
    int *chosen;  /* [n]: chosen[k] = r at depth k (0-indexed k, 1-indexed r) */
    UndoEntry *undo;
    int undo_top, undo_cap;
    int *tree_buf;    /* [n_trees * (n-1)]: 1-indexed edge IDs per tree */
    int n_trees, trees_cap;
    int counting_only;
    int *selected;    /* [n-1]: temp buffer for expand_product */
    /* edges[e*2+0]=j, edges[e*2+1]=i: 1-indexed relabeled endpoints, j>i, e=0..m-1 */
    int *edges;
    /* inv_label[lbl] = 0-indexed original vertex (lbl=0..n-1) */
    int *inv_label;
} EnumState;

static void expand_product(EnumState *s, int level) {
    int n = s->n;
    int n1 = n - 1;
    if (level == n1) {
        if (!s->counting_only) {
            memcpy(s->tree_buf + s->n_trees * n1, s->selected, n1 * sizeof(int));
        }
        s->n_trees++;
        return;
    }
    /* edge_set for level k: E[tri(n-k, chosen[k])] */
    int nk = n - level;    /* 1-indexed vertex */
    int r = s->chosen[level];
    int pair = tri(nk, r);
    int len = s->E_len[pair];
    int *eids = s->E_data + pair * (s->m + 1);
    for (int ei = 0; ei < len; ei++) {
        s->selected[level] = eids[ei];
        expand_product(s, level + 1);
    }
}

static void contract(EnumState *s, int k) {
    int n = s->n;
    int nk = n - k;    /* 1-indexed vertex being processed */
    int *EE_nk = s->EE_data + (nk - 1) * n;
    int EE_nk_len = s->EE_len[nk];

    for (int ri = 0; ri < EE_nk_len; ri++) {
        int r = EE_nk[ri];    /* 1-indexed, iterates in decreasing order */
        s->chosen[k] = r;

        if (nk == 2) {
            expand_product(s, 0);
        } else {
            int undo_start = s->undo_top;
            /* Merge E[nk][i] into E[r][i] for all i < r in EE_nk.
             * Since EE_nk is sorted decreasingly and EE_nk[ri]=r,
             * elements at ri+1..end are all < r. */
            for (int ii = ri + 1; ii < EE_nk_len; ii++) {
                int i = EE_nk[ii];
                int src_pair = tri(nk, i);
                int dst_pair = tri(r, i);
                int old_len = s->E_len[dst_pair];
                int src_len = s->E_len[src_pair];

                memcpy(
                    s->E_data + dst_pair * (s->m + 1) + old_len,
                    s->E_data + src_pair * (s->m + 1),
                    src_len * sizeof(int)
                );
                s->E_len[dst_pair] = old_len + src_len;

                /* If E[r][i] was empty, insert i into EE[r] (maintain decreasing order) */
                if (old_len == 0) {
                    int *EE_r = s->EE_data + (r - 1) * n;
                    int rlen = s->EE_len[r];
                    int pos = 0;
                    while (pos < rlen && EE_r[pos] > i) pos++;
                    memmove(EE_r + pos + 1, EE_r + pos, (rlen - pos) * sizeof(int));
                    EE_r[pos] = i;
                    s->EE_len[r]++;
                }

                s->undo[s->undo_top].r = r;
                s->undo[s->undo_top].i = i;
                s->undo[s->undo_top].old_len = old_len;
                s->undo_top++;
            }

            contract(s, k + 1);

            /* Restore state in reverse */
            for (int ui = s->undo_top - 1; ui >= undo_start; ui--) {
                UndoEntry u = s->undo[ui];
                int pair = tri(u.r, u.i);
                if (u.old_len == 0) {
                    int *EE_r = s->EE_data + (u.r - 1) * n;
                    int rlen = s->EE_len[u.r];
                    int pos = 0;
                    while (pos < rlen && EE_r[pos] != u.i) pos++;
                    memmove(EE_r + pos, EE_r + pos + 1, (rlen - pos - 1) * sizeof(int));
                    s->EE_len[u.r]--;
                }
                s->E_len[pair] = u.old_len;
            }
            s->undo_top = undo_start;
        }
    }
}

SEXP enumerate_spanning_trees_c(SEXP graph_R) {
    int n = Rf_length(graph_R);

    /* ---- Step 1: Proper labeling (BFS from max-degree vertex) ---- */
    int *deg = (int *)R_alloc(n, sizeof(int));
    for (int v = 0; v < n; v++) {
        deg[v] = Rf_length(VECTOR_ELT(graph_R, v));
    }

    /* inv_label[lbl] = 0-indexed original vertex (lbl = 0..n-1) */
    int *inv_label = (int *)R_alloc(n, sizeof(int));
    /* label[v] = 1-indexed new label for 0-indexed original vertex v */
    int *label = (int *)R_alloc(n, sizeof(int));
    int *labeled = (int *)R_alloc(n, sizeof(int));
    int *frontier_deg = (int *)R_alloc(n, sizeof(int));

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
        int *arr = INTEGER(nbrs);
        int d = Rf_length(nbrs);
        for (int j = 0; j < d; j++) {
            int v = arr[j] - 1;    /* 0-indexed */
            frontier_deg[v] = deg[v];
        }
    }

    for (int lbl = 1; lbl < n; lbl++) {
        int best = -1;
        for (int v = 0; v < n; v++) {
            if (frontier_deg[v] >= 0 && (best < 0 || frontier_deg[v] > frontier_deg[best]))
                best = v;
        }
        inv_label[lbl] = best;
        labeled[best] = 1;
        frontier_deg[best] = -1;
        SEXP nbrs = VECTOR_ELT(graph_R, best);
        int *arr = INTEGER(nbrs);
        int d = Rf_length(nbrs);
        for (int j = 0; j < d; j++) {
            int v = arr[j] - 1;
            if (!labeled[v] && frontier_deg[v] == -1)
                frontier_deg[v] = deg[v];
        }
    }

    for (int lbl = 0; lbl < n; lbl++) {
        label[inv_label[lbl]] = lbl + 1;    /* 1-indexed new label */
    }

    /* ---- Step 2: Build edge list in relabeled space ---- */
    int m = 0;
    for (int u = 0; u < n; u++) {
        SEXP nbrs = VECTOR_ELT(graph_R, u);
        int *arr = INTEGER(nbrs);
        int d = Rf_length(nbrs);
        for (int k = 0; k < d; k++) {
            if (u < arr[k] - 1) m++;
        }
    }

    /* edges[e*2+0]=j, edges[e*2+1]=i: 1-indexed relabeled, j>i, e=0..m-1 */
    int *edges = (int *)R_alloc(m * 2, sizeof(int));
    int eid = 0;
    for (int u = 0; u < n; u++) {
        SEXP nbrs = VECTOR_ELT(graph_R, u);
        int *arr = INTEGER(nbrs);
        int d = Rf_length(nbrs);
        for (int k = 0; k < d; k++) {
            int v = arr[k] - 1;
            if (u < v) {
                int lu = label[u], lv = label[v];
                edges[eid * 2 + 0] = (lu > lv) ? lu : lv;
                edges[eid * 2 + 1] = (lu > lv) ? lv : lu;
                eid++;
            }
        }
    }

    /* ---- Step 3: Initialize EnumState ---- */
    int n_pairs = n * (n - 1) / 2;

    EnumState s;
    s.n = n;
    s.m = m;
    s.n_pairs = n_pairs;
    s.edges = edges;
    s.inv_label = inv_label;

    s.E_data = (int *)R_alloc((size_t)n_pairs * (m + 1), sizeof(int));
    s.E_len  = (int *)R_alloc(n_pairs, sizeof(int));
    s.EE_data = (int *)R_alloc((size_t)n * n, sizeof(int));
    s.EE_len  = (int *)R_alloc(n + 1, sizeof(int));
    s.chosen  = (int *)R_alloc(n, sizeof(int));
    s.undo_cap = (m + 1) * n;
    s.undo    = (UndoEntry *)R_alloc(s.undo_cap, sizeof(UndoEntry));
    s.selected = (int *)R_alloc(n - 1, sizeof(int));

    memset(s.E_data, 0, (size_t)n_pairs * (m + 1) * sizeof(int));
    memset(s.E_len,  0, n_pairs * sizeof(int));
    memset(s.EE_data, 0, (size_t)n * n * sizeof(int));
    memset(s.EE_len,  0, (n + 1) * sizeof(int));

    /* Fill E: E[tri(j,i)] gets the 1-indexed edge ID e+1 */
    for (int e = 0; e < m; e++) {
        int j = edges[e * 2 + 0];
        int i = edges[e * 2 + 1];
        int p = tri(j, i);
        s.E_data[p * (m + 1) + s.E_len[p]] = e + 1;
        s.E_len[p]++;
    }

    /* Fill EE: for each vertex j, collect active i-values in decreasing order */
    for (int j = 2; j <= n; j++) {
        int *EE_j = s.EE_data + (j - 1) * n;
        int cnt = 0;
        for (int i = j - 1; i >= 1; i--) {
            if (s.E_len[tri(j, i)] > 0) EE_j[cnt++] = i;
        }
        s.EE_len[j] = cnt;
    }

    /* ---- Step 4: Pass 1 — count spanning trees ---- */
    s.tree_buf = NULL;
    s.trees_cap = 0;
    s.n_trees = 0;
    s.undo_top = 0;
    s.counting_only = 1;
    contract(&s, 0);
    int total_trees = s.n_trees;

    /* ---- Step 5: Pass 2 — collect spanning trees ---- */
    /* Re-run with tree storage; E/EE are restored to initial state after pass 1. */
    if (total_trees > 0) {
        s.tree_buf = (int *)R_alloc((size_t)total_trees * (n - 1), sizeof(int));
        s.trees_cap = total_trees;
        s.n_trees = 0;
        s.undo_top = 0;
        s.counting_only = 0;
        contract(&s, 0);
    }

    /* ---- Step 6: Build R list of adj objects ---- */
    SEXP result = PROTECT(Rf_allocVector(VECSXP, total_trees));

    /* Shared class and attribute strings reused across all trees */
    SEXP cls      = PROTECT(Rf_allocVector(STRSXP, 2));
    SEXP dup_str  = PROTECT(Rf_mkString("error"));
    SEXP loop_str = PROTECT(Rf_mkString("error"));
    SET_STRING_ELT(cls, 0, Rf_mkChar("adj"));
    SET_STRING_ELT(cls, 1, Rf_mkChar("list"));
    SEXP dup_sym  = Rf_install("duplicates");
    SEXP loop_sym = Rf_install("self_loops");

    int n1 = n - 1;
    int *tmp_deg = (int *)R_alloc(n, sizeof(int));
    int *tmp_off = (int *)R_alloc(n, sizeof(int));

    for (int t = 0; t < total_trees; t++) {
        int *eids = s.tree_buf + t * n1;

        /* Count degree of each original vertex in this tree */
        memset(tmp_deg, 0, n * sizeof(int));
        for (int k = 0; k < n1; k++) {
            int e    = eids[k] - 1;            /* 0-indexed edge */
            int j_r  = edges[e * 2 + 0] - 1;  /* 0-indexed relabeled */
            int i_r  = edges[e * 2 + 1] - 1;
            int oj   = inv_label[j_r];         /* 0-indexed original */
            int oi   = inv_label[i_r];
            tmp_deg[oj]++;
            tmp_deg[oi]++;
        }

        /* Allocate neighbor vectors */
        SEXP tree_adj = PROTECT(Rf_allocVector(VECSXP, n));
        for (int v = 0; v < n; v++) {
            SEXP nbr_v = PROTECT(Rf_allocVector(INTSXP, tmp_deg[v]));
            SET_VECTOR_ELT(tree_adj, v, nbr_v);
            UNPROTECT(1);
            tmp_off[v] = 0;
        }

        /* Fill neighbor vectors (1-indexed for R) */
        for (int k = 0; k < n1; k++) {
            int e   = eids[k] - 1;
            int j_r = edges[e * 2 + 0] - 1;
            int i_r = edges[e * 2 + 1] - 1;
            int oj  = inv_label[j_r];
            int oi  = inv_label[i_r];
            INTEGER(VECTOR_ELT(tree_adj, oj))[tmp_off[oj]++] = oi + 1;
            INTEGER(VECTOR_ELT(tree_adj, oi))[tmp_off[oi]++] = oj + 1;
        }

        Rf_setAttrib(tree_adj, R_ClassSymbol, cls);
        Rf_setAttrib(tree_adj, dup_sym,  dup_str);
        Rf_setAttrib(tree_adj, loop_sym, loop_str);

        SET_VECTOR_ELT(result, t, tree_adj);
        UNPROTECT(1);    /* tree_adj (now held by result) */
    }

    UNPROTECT(4);    /* result, cls, dup_str, loop_str */
    return result;
}
