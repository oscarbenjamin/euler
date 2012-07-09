
import numpy as np

def euler(f, x0, t):
    X = np.zeros((len(t), len(x0)), float)
    dxdt = np.zeros(len(x0), float)

    X[0, :] = x = np.array(x0)
    tlast = t[0]

    for n, tcur in enumerate(t[1:], 1):
        f(x, tlast, dxdt)
        X[n, :] = x = x + dxdt * (tcur - tlast)
        tlast = tcur

    return X

def func(x, t, dxdt):
    dxdt[0] = x[1]
    dxdt[1] = - x[0]
