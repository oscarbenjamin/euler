
import numpy as np
import euler_12

class pyODES_sub(euler_12.pyODES):
    def func(self, x, t, dxdt):
        dxdt[0] = x[1]
        dxdt[1] = - x[0]

def euler(x0, t):
    return pyODES_sub().euler(x0, t)
