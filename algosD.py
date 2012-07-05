
import numpy as np
import algosC

class pyODES_sub(algosC.pyODES):
    def func(self, x, t, dxdt):
        dxdt[0] = x[1]
        dxdt[1] = - x[0]

def accum(x0, t):
    return pyODES_sub().accum(x0, t)
