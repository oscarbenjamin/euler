import numpy as np
cimport numpy as np

ctypedef np.float64_t DTYPE_t

cpdef euler(np.ndarray[DTYPE_t, ndim=1] x0, np.ndarray[DTYPE_t, ndim=1] t):

    cdef int n, m, N, M
    cdef np.ndarray[DTYPE_t, ndim=2] X
    cdef np.ndarray[DTYPE_t, ndim=1] x
    cdef np.ndarray[DTYPE_t, ndim=1] dxdt
    cdef double dt, tcur, tlast, *px, *pt, *pdxdt, *pX

    N = len(x0)
    M = len(t)

    X = np.zeros((M, N), float)
    x = np.zeros(N, float)
    dxdt = np.zeros(N, float)

    px = <double*>x.data
    pt = <double*>t.data
    pdxdt = <double*>dxdt.data
    pX = <double*>X.data

    # Pre-loop setup
    for n in range(N):
        pX[0 + n] = px[n] = <double>x0[n]
    tlast = pt[0]

    # Main loop
    for m in range(1, M):
        tcur = pt[m]
        dt = tcur - tlast
        func(px, tlast, pdxdt)
        for n in range(N):
            px[n] += pdxdt[n] * dt
            pX[m*N + n] = px[n]
        tlast = tcur

    # Final result
    return X

# This one is used by the euler function defined above
cdef void func(double* x, double t, double* dxdt):
    dxdt[0] = x[1]
    dxdt[1] = - x[0]
