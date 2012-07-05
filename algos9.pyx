import numpy as np
cimport numpy as np

ctypedef np.float64_t DTYPE_t

# This one is used by the accum function defined above
cdef inline func(double* x, double t, double* dxdt):
    dxdt[0] = x[1]
    dxdt[1] = - x[0]

cdef class ODES:

    def func(self, np.ndarray[DTYPE_t, ndim=1] x, double t,
                   np.ndarray[DTYPE_t, ndim=1] dxdt):
        self._func(<double*>x.data, t, <double*>dxdt.data)
        return dxdt

    cdef _func(self, double* x, double t, double* dxdt):
        dxdt[0] = x[1]
        dxdt[1] = - x[0]

    cpdef accum(self, np.ndarray[DTYPE_t, ndim=1] x0, np.ndarray[DTYPE_t, ndim=1] t):

        cdef int m, N, M
        cdef np.ndarray[DTYPE_t, ndim=2] X
        cdef np.ndarray[DTYPE_t, ndim=1] x
        cdef np.ndarray[DTYPE_t, ndim=1] dxdt
        cdef double dt, tcur, tlast, *px, *pt, *pdxdt

        N = len(x0)
        M = len(t)

        X = np.zeros((M, N), float)
        x = np.zeros(N, float)
        dxdt = np.zeros(N, float)

        px = <double*>x.data
        pt = <double*>t.data
        pdxdt = <double*>dxdt.data

        # Pre-loop setup
        for n in range(N):
            X[0, n] = px[n] = x0[n]
        tlast = t[0]

        # Main loop
        for m in range(1, M):
            tcur = pt[m]
            dt = tcur - tlast
            self._func(px, tlast, pdxdt)
            for n in range(N):
                x[n] += pdxdt[n] * dt
                X[m, n] = x[n]
            tlast = tcur
        return X

def accum(x0, t):
    return ODES().accum(x0, t)