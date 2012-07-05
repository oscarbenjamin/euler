
import numpy as np
cimport numpy as np

ctypedef np.float64_t DTYPE_t

cpdef accum(f, np.ndarray[DTYPE_t, ndim=1] x0, np.ndarray[DTYPE_t, ndim=1] t):
    cdef int n, m, N, M
    cdef np.ndarray[DTYPE_t, ndim=2] X
    cdef np.ndarray[DTYPE_t, ndim=1] x, dxdt
    cdef double dt, tcur, tlast

    N = len(x0)
    M = len(t)

    X = np.zeros((M, N), float)
    x = np.zeros(N, float)
    dxdt = np.zeros(N, float)

    # Pre-loop setup
    for n in range(N):
        X[0, n] = x[n] = x0[n]
    tlast = t[0]

    # Main loop
    for m in range(1, M):
        tcur = t[m]
        dt = tcur - tlast
        func(x, tlast, dxdt)
        for n in range(N):
            x[n] += dxdt[n] * dt
            X[m, n] = x[n]
        tlast = tcur
    return X

cpdef func(np.ndarray[DTYPE_t, ndim=1] x, double t,
           np.ndarray[DTYPE_t, ndim=1] dxdt):
    dxdt[0] = x[1]
    dxdt[1] = - x[0]
