#!/usr/bin/env python

from __future__ import division

import timeit

from pylab import *

import algos1
import algos2

x0 = array([0., 1.])
t = arange(0, 10, 0.01)

setup = 'from __main__ import algos1, algos2, x0, t'

statements = [
    'algos1.accum(algos1.func, x0, t)',
    'algos1.accum(algos2.func, x0, t)',
    'algos2.accum(algos1.func, x0, t)',
    'algos2.accum(algos2.func, x0, t)',
]

REPEAT = 20
for stmt in statements:
    result = timeit.timeit(stmt, setup, number=REPEAT)
    print 'stmt: {0}  t: {1}'.format(stmt, result / REPEAT)

#plot(t, X)
#show()
