
import numpy as np

def algo(f, x, t, dt):
    return x + f(x, t) * dt

def accum(f, x, t):
    X = np.zeros((len(t), len(x)), float)
    dxdt = np.zeros(len(x), float)
    for n, tcur in enumerate(t):
        if not n:
            X[n, :] = x
        else:
            f(x, tlast, dxdt)
            X[n, :] = x = x + dxdt * (tcur - tlast)
        tlast = tcur
    return X

def func(x, t, dxdt):
    dxdt[0] = x[1]
    dxdt[1] = - x[0]
