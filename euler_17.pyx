import collections

from libc.stdlib cimport malloc, free

import numpy as np
cimport numpy as np

ctypedef np.float64_t real
ctypedef unsigned int number

cdef class Array:
    cdef readonly number length
    cdef real* data

    def __cinit__(self, number length, data=None):
        self.length = length
        self.data = <real*>malloc(length * sizeof(real))
        if self.data is NULL:
            raise MemoryError()
        if data is not None:
            if len(data) != self.length:
                raise ValueError('data size does not match length')
            for n, value in enumerate(data):
                self.data[n] = <real>value

    def __dealloc__(self):
        free(self.data)
        self.data = NULL

    def __repr__(self):
        data_list = [self.data[n] for n in range(self.length)]
        return 'Array({0!r}, {1!r})'.format(self.length, data_list)

    cpdef zero_out(self):
        cdef number i
        for i in range(self.length):
            self.data[i] = 0

    def __setitem__(self, number index, real value):
        self.data[index] = value

    def __getitem__(self, number index):
        return self.data[index]

    cdef void itemset(self, number index, real value):
        self.data[index] = value

    cdef real item(self, number index):
        return self.data[index]

cdef class ODES:

    cpdef func(self, Array x, real t, Array dxdt):
        dxdt.itemset(0, x.item(1))
        dxdt.itemset(1, - x.item(0))

    cdef void _func(self, real* x, real t, real* dxdt):
        raise NotImplementedError

    cpdef euler(self, np.ndarray[real, ndim=1] x0, np.ndarray[real, ndim=1] t):

        cdef int n, m, N, M
        cdef np.ndarray[real, ndim=2] X
        cdef Array x, dxdt
        cdef real dt, tcur, tlast, *px, *pt, *pdxdt, *pX

        N = len(x0)
        M = len(t)

        X = np.zeros((M, N), float)
        x = Array(N)
        dxdt = Array(N)

        px = <real*>x.data
        pt = <real*>t.data
        pdxdt = <real*>dxdt.data
        pX = <real*>X.data

        # Pre-loop setup
        for n in range(N):
            pX[0 + n] = px[n] = <real>x0[n]
        tlast = t[0]

        # Main loop
        for m in range(1, M):
            tcur = pt[m]
            dt = tcur - tlast
            self.func(x, tlast, dxdt)
            for n in range(N):
                px[n] += pdxdt[n] * dt
                pX[m*N + n] = px[n]
            tlast = tcur
        return X

cdef class ODES_sub(ODES):

    cdef void _func(self, real* x, real t, real* dxdt):
        dxdt[0] = x[1]
        dxdt[1] = - x[0]

def euler(x0, t):
    return ODES_sub().euler(x0, t)
