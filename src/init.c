#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

#include <stdlib.h>
#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>

extern SEXP enumerate_spanning_trees_c(SEXP graph_R, SEXP count_R);
extern SEXP enumerate_spanning_trees_matrix_c(SEXP graph_R, SEXP count_R);

static const R_CallMethodDef CallEntries[] = {
    {"enumerate_spanning_trees_c",        (DL_FUNC) &enumerate_spanning_trees_c,        2},
    {"enumerate_spanning_trees_matrix_c", (DL_FUNC) &enumerate_spanning_trees_matrix_c, 2},
    {NULL, NULL, 0}
};

void attribute_visible R_init_crann(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
