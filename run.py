#!/usr/bin/env python

from __future__ import division

import timeit
import sys

from pylab import *

import algos1, algos2, algos3

x0 = array([0., 1.])
t = arange(0, 10, 0.01)

setup = 'from __main__ import algos1, algos2, algos3, x0, t'

statements = [
    'algos1.accum(algos1.func, x0, t)',
    'algos1.accum(algos2.func, x0, t)',
    'algos2.accum(algos1.func, x0, t)',
    'algos2.accum(algos2.func, x0, t)',
    'algos3.accum(x0, t)',
]

args = sys.argv[1:]


# Time all the statements
if not args:
    REPEAT = 20
    for stmt in statements:
        result = timeit.timeit(stmt, setup, number=REPEAT)
        usecs = int(1e6 * result / REPEAT)
        print 'stmt: {0:40}  t: {1} usecs'.format(stmt, usecs)

# Plot the results from executing a particular statement
elif len(args) == 1:
    stmt = statements[int(args[0])]
    print stmt
    X = eval(stmt)
    plot(t, X)
    show()
