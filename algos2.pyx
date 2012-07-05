import numpy as np
cimport numpy as np

ctypedef np.float64_t DTYPE_t

cpdef accum(f, np.ndarray[DTYPE_t, ndim=1] x, np.ndarray[DTYPE_t, ndim=1] t):

    cdef int m, N, M
    cdef np.ndarray[DTYPE_t, ndim=2] X
    cdef np.ndarray[DTYPE_t, ndim=1] dxdt

    N = len(x)
    M = len(t)
    X = np.zeros((M, N), float)
    dxdt = np.zeros(N, float)

    X[0, :] = x

    for m in range(1, M):
        func2(<double*>x.data, <double>t[m], <double*>dxdt.data)
        X[m, :] = x = x + dxdt * (t[m] - t[m-1])
    return X

cdef func2(double* x, double t, double* dxdt):
    dxdt[0] = x[1]
    dxdt[1] = - x[0]

def func(x, t, dxdt):
    dxdt[0] = x[1]
    dxdt[1] = - x[0]
