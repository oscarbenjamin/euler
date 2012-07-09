EULER
=====

Intro
-----

This repo hosts my attempts at using cython to create an library that defines
an forward-Euler integration routine. This is a proxy for prototyping the
structure that I will use in SODE. The situation is that the library should
define an algorithm - in this case forward-Euler - and a user of the library
should define the function that the algorithm will operate on. My objective is
that the user should be able to:

1. Use the library with a pure python function for learning or debugging. In
   this case performance is not a concern.
2. Use the library with a function defined in a cython extension module for
   better performance. This case should perform as fast as possible.

Ideally the code used for the python/cython versions should be as similar as
possible so that converting a pure python version to its cython equivalent
should be trivial.

The basic problem is how to achieve maximum efficiency in the pure cython case
while still allowing users the flexibility to supply a function from pure
python.

Outline
-------

The first attempt is in pure python and looks like::
    :language: python

    # euler_01.py
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

The idea is that the function `euler` is defined in the library and the
function `func` is defined in a script written by a user of the library. The
function `func` is chosen to describe the Ordinary Differential Equations of
Simple Harmonic Motion. The function `euler` will perform forward Euler
integration of the function to produce an array `X` representing the state of
the system at times corresponding to the elements of `t`. We can run this with
a script like::
    :language: python

    # script.py

    from pylab import *
    import euler_01

    x0 = array([0., 1.])
    t = arange(0, 10, 0.01)

    X = euler_01.euler(euler_01.func, x0, t)

    plot(t, X)
    show()

We want to improve on the performance of the above routine by implementing
`euler` in cython code and allowing a user to implement `func` in cython code
and have the result achieve performance close to what would be avilable in
pure-c.

Files
-----

The files `euler_N.{py|pyx}` in this repo represent different attempts at
achieving this. To build all of the cython extension modules run::
    :language: terminal

    $ python setup.py build_ext --inplace

To test the `euler_08` implementation do::
    :language: terminal

    $ python run.py 08

which will plot the results using matplotlib.

To test the performance of all of the implementations, do::
    :language: terminal

    $ ./run.py
    stmt: euler_01.euler(euler_01.func, x0, t)      t: 14574 usecs
    stmt: euler_02.euler(euler_02.func, x0, t)      t: 16826 usecs
    stmt: euler_03.euler(euler_03.func, x0, t)      t: 3118 usecs
    stmt: euler_04.euler(x0, t)                     t: 1693 usecs
    stmt: euler_05.euler(x0, t)                     t: 1512 usecs
    stmt: euler_06.euler(x0, t)                     t: 1491 usecs
    stmt: euler_07.euler(x0, t)                     t: 29 usecs
    stmt: euler_08.euler(x0, t)                     t: 31 usecs
    stmt: euler_09.euler(x0, t)                     t: 41 usecs
    stmt: euler_10.euler(x0, t)                     t: 44 usecs
    stmt: euler_11.euler(x0, t)                     t: 1494 usecs
    stmt: euler_12.euler(x0, t)                     t: 40 usecs
    stmt: euler_13.euler(x0, t)                     t: 4531 usecs

My interpretation of the above performance differences is as follows.

1. `euler_01` is a pure python implementation and takes 15 millisseconds to
run the test.
2. `euler_02` reimplements `euler_01` in cython using `cpdef` functions with
and static typing. The function `func` is passed as an argument to the
`euler_02.euler` function. This means that, although it is implemented in c,
`func` is called through its python interface. The overhead of calling into a
`cpdef` function through its python interface actually increases the time
taken to around 17 milliseconds.
3. `euler_03` improves on `euler_02` by eliminating the creation of temparoray
arrays and performing all array assignments with `cdef`'d integers. This
brings the total running time down to about 3 milliseconds which is a factor
of 5 improvement over the original pure python implementation.
4. `euler_04` sacrifices the flexibility of being able to pass in any function
you like by explicitly calling `func` from the `euler` routine. This ensures
that the `cpdef` function is always called via its c interface and cuts the
running time by a further 50% (factor of 10 improvement over pure python).
5. `euler_05` attempts to improve performance by using disabling `wraparound`
and `boundscheck` in the generated cython code. Unfortunately this only gives
a small improvement.
6. `euler_06` attempts to improve on the performance of `euler_05` by
extracting the data pointer from the numpy array in `func` before assigning to
it. This results in only a very small improvement.
7. `euler_07` uses `cdef` functions and `double` pointers everywhere and
the `cdef`'d `euler` routine explicitly calls the `cdef`'d `func` routine.
This results in a massive performance boost. The time taken is now 30
microseconds, which is 50 times faster than `euler_08` and 500 times faster
than pure python. This is probably close to the performance that would be
available in pure c. This does, however, make it impossible for a user to
supply their own `func` to the library.
8. `euler_08` attempts to go even further by making `func` an inline function.
This actually incurs a small performance penalty.
9. `euler_09` defines an extension type `ODES` with methods `euler` and
`_func`. This enables `_func` to be customised by subclassing `ODES` in
another cython module. This incurs a 33% increase in running time relative to
the super-fast `euler_07`.
10. `euler_10` is the same as `euler_09` but shows the performance when
running with a subclass of `ODES` as a library user would. This has a roughly
50% overhead compared to `euler_07`.
11. `euler_11` attempts to make the more efficient `euler_07-10`
implementations more flexible, by adding a `cpdef` function `func` that can be
overridden by subclassing in pure python. The default implementation of `func`
calls into a `cdef` function `_func` that can only be overridden by
subclassing in cython code. This makes it possible to subclass in python or
cython and override `func` or `_func` respectively. Unfortunately, the
overhead of calling into the `cpdef`'d function `func` reduces performance
massively.
12. `euler_12` achieves the same flexibility as `euler_11` without the
performance cost by creating two extension types. A user who wants to write
something in pure python must subclass `pyODES` instead of `ODES` and override
`func` instead of `_func`. The performance of this variant is about 33% worse
than the fastest version `euler_07` while keeping the intended flexibility
that a user can override the methods in either python or cython. It is,
however, unfortunate to have to subclass a different type and override a
different method. Also if there would be subclasses of `ODES`, then each would
need a corresponding `py` variant to be usable from pure python.
13. `euler_13` demonstrates subclassing `pyODES` from `euler_12`. The
performance is better than the pure python `euler_01` by a factor of about 3
Performance is not really a concern if the user is operating in pure python
but it's good to know that we haven't incurred a penalty for the pure python
mode by introducing all of the cython infrastructure.


