import numpy as np
cimport numpy as np
np.import_array()

ctypedef np.float64_t DTYPE_t

# This one is used by the euler function defined above
cdef inline func(double* x, double t, double* dxdt):
    dxdt[0] = x[1]
    dxdt[1] = - x[0]

cdef class ODES:

    cdef int nvars

    def __cinit__(self):
        self.nvars = 2

    def func(self, np.ndarray[DTYPE_t, ndim=1] x, double t,
                   np.ndarray[DTYPE_t, ndim=1] dxdt):
        self._func(<double*>x.data, t, <double*>dxdt.data)

    cdef void _func(self, double* x, double t, double* dxdt):
        raise NotImplementedError

    cpdef euler(self, np.ndarray[DTYPE_t, ndim=1] x0, np.ndarray[DTYPE_t, ndim=1] t):

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
        tlast = t[0]

        # Main loop
        for m in range(1, M):
            tcur = pt[m]
            dt = tcur - tlast
            self._func(px, tlast, pdxdt)
            for n in range(N):
                px[n] += pdxdt[n] * dt
                pX[m*N + n] = px[n]
            tlast = tcur
        return X

cdef class pyODES(ODES):

    cdef np.ndarray[DTYPE_t, ndim=1] _ptr_to_numpy_array(self, double* data, int size):
        cdef np.npy_intp shape[1]
        shape[0] = <np.npy_intp>size
        return np.PyArray_SimpleNewFromData(1, shape, np.NPY_FLOAT64, <void*>data)

    cdef void _func(self, double* x, double t, double* dxdt):
        cdef int n
        cdef np.ndarray[DTYPE_t, ndim=1] npx, npdxdt
        npx = self._ptr_to_numpy_array(x, self.nvars)
        npdxdt = self._ptr_to_numpy_array(dxdt, self.nvars)
        self.func(npx, t, npdxdt)

    def func(self, np.ndarray[DTYPE_t, ndim=1] x, double t,
                   np.ndarray[DTYPE_t, ndim=1] dxdt):
        raise NotImplementedError

cdef class ODES_sub(ODES):

    cdef void _func(self, double* x, double t, double* dxdt):
        dxdt[0] = x[1]
        dxdt[1] = - x[0]

def euler(x0, t):
    return ODES_sub().euler(x0, t)
