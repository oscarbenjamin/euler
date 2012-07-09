
import numpy as np
import euler_17

class ODES_sub(euler_17.ODES):
    def func(self, x, t, dxdt):
        dxdt[0] = x[1]
        dxdt[1] = - x[0]

def euler(x0, t):
    return ODES_sub().euler(x0, t)
