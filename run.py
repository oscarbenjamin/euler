#!/usr/bin/env python

from __future__ import division

import timeit
import sys

from pylab import *

import euler_01, euler_02, euler_03, euler_04, euler_05
import euler_06, euler_07, euler_08, euler_09, euler_10
import euler_11, euler_12, euler_13, euler_14, euler_15
import euler_16

x0 = array([0., 1.])
t = arange(0, 10, 0.01)

setup = '''
from __main__ import (euler_01, euler_02, euler_03, euler_04,
                      euler_05, euler_06, euler_07, euler_08,
                      euler_09, euler_10, euler_11, euler_12,
                      euler_13, euler_14, euler_15, euler_16, x0, t)
'''

statements = [
    'euler_01.euler(euler_01.func, x0, t)',
    'euler_02.euler(euler_02.func, x0, t)',
    'euler_03.euler(euler_03.func, x0, t)',
    'euler_04.euler(x0, t)',
    'euler_05.euler(x0, t)',
    'euler_06.euler(x0, t)',
    'euler_07.euler(x0, t)',
    'euler_08.euler(x0, t)',
    'euler_09.euler(x0, t)',
    'euler_10.euler(x0, t)',
    'euler_11.euler(x0, t)',
    'euler_12.euler(x0, t)',
    'euler_13.euler(x0, t) # py - euler_12',
    'euler_14.euler(x0, t) # py - euler_11',
    'euler_15.euler(x0, t)',
    'euler_16.euler(x0, t) # py - euler_15',
]

args = sys.argv[1:]


# Time all the statements
if not args:
    REPEAT = 100
    for stmt in statements:
        result = timeit.timeit(stmt, setup, number=REPEAT)
        usecs = int(1e6 * result / REPEAT)
        print 'stmt: {0:40}  t: {1} usecs'.format(stmt, usecs)

# Plot the results from executing a particular statement
elif len(args) == 1:
    stmt = statements[int(args[0]) - 1]
    print stmt
    X = eval(stmt)
    plot(t, X)
    show()
