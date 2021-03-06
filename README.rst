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

    $ python setup.py build_ext --inplace

To test the `euler_08` implementation do::

    $ python run.py 08

which will plot the results using matplotlib.

To test the performance of all of the implementations, do::

    $ ./run.py
    stmt: euler_01.euler(euler_01.func, x0, t)      t: 14382 usecs
    stmt: euler_02.euler(euler_02.func, x0, t)      t: 16687 usecs
    stmt: euler_03.euler(euler_03.func, x0, t)      t: 2859 usecs
    stmt: euler_04.euler(x0, t)                     t: 1482 usecs
    stmt: euler_05.euler(x0, t)                     t: 1448 usecs
    stmt: euler_06.euler(x0, t)                     t: 1405 usecs
    stmt: euler_07.euler(x0, t)                     t: 30 usecs
    stmt: euler_08.euler(x0, t)                     t: 29 usecs
    stmt: euler_09.euler(x0, t)                     t: 41 usecs
    stmt: euler_10.euler(x0, t)                     t: 38 usecs
    stmt: euler_11.euler(x0, t)                     t: 1424 usecs
    stmt: euler_12.euler(x0, t) # py - euler_11     t: 2783 usecs
    stmt: euler_13.euler(x0, t)                     t: 42 usecs
    stmt: euler_14.euler(x0, t) # py - euler_13     t: 4537 usecs
    stmt: euler_15.euler(x0, t)                     t: 171 usecs
    stmt: euler_16.euler(x0, t) # py - euler_15     t: 570 usecs
    stmt: euler_17.euler(x0, t)                     t: 55 usecs
    stmt: euler_18.euler(x0, t) # py - euler_17     t: 556 usecs
    stmt: euler_19.euler(x0, t)                     t: 42 usecs
    stmt: euler_20.euler(x0, t) # py - euler_19     t: 817 usecs

My interpretation of the above performance differences follows. The general
gist is that upto `euler_08` we are just trying to get the test to run as fast
as possible. `euler_09` and `euler_10` aim to keep that speed whilst making it
possible to set the function from user cython code by subclassing an extension
type, bringing a 33% performance penalty. `euler_11` onwards attempt to make
is possible to subclass in both cython and python whilst adding as little as
possible overhead to the cython case.

1.  `euler_01` is a pure python implementation and takes 15 millisseconds
to run the test.

2.  `euler_02` reimplements `euler_01` in cython using `cpdef` functions
with and static typing. The function `func` is passed as an argument to
the `euler_02.euler` function. This means that, although it is implemented
in c, `func` is called through its python interface. The overhead of
calling into a `cpdef` function through its python interface actually
increases the time taken to around 17 milliseconds.

3.  `euler_03` improves on `euler_02` by eliminating the creation of
temparoray arrays and performing all array assignments with `cdef`'d
integers. This brings the total running time down to about 3 milliseconds
which is a factor of 5 improvement over the original pure python
implementation.

4.  `euler_04` sacrifices the flexibility of being able to pass in any
function you like by explicitly calling `func` from the `euler` routine.
This ensures that the `cpdef` function is always called via its c
interface and cuts the running time by a further 50% (factor of 10
improvement over pure python).

5.  `euler_05` attempts to improve performance by using disabling
`wraparound` and `boundscheck` in the generated cython code. Unfortunately
this only gives a small improvement.

6.  `euler_06` attempts to improve on the performance of `euler_05` by
doing all of the manipulations in `euler` using `double` pointers but still
using a `cpdef` function and `numpy.ndarray` for `func`. This results in a
small performance increase.

7.  `euler_07` uses `cdef` functions and `double` pointers everywhere and
the `cdef`'d `euler` routine explicitly calls the `cdef`'d `func` routine.
This results in a massive performance boost. The time taken is now 30
microseconds, which is 50 times faster than `euler_08` and 500 times
faster than pure python. This is probably close to the performance that
would be available in pure c. This does, however, make it impossible for a
user to supply their own `func` to the library.

8.  `euler_08` attempts to go even further by making `func` an inline
function.  This actually incurs a small performance penalty.

9.  `euler_09` defines an extension type `ODES` with methods `euler` and
`_func`. This enables `_func` to be customised by subclassing `ODES` in
another cython module. This incurs a 33% increase in running time relative
to the super-fast `euler_07`.

10. `euler_10` is the same as `euler_09` but shows the performance when
running with a subclass of `ODES` as a library user would. This has a
roughly 50% overhead compared to `euler_07`.

11.  `euler_11` attempts to make the more efficient `euler_07-10`
implementations more flexible, by adding a `cpdef` function `func` that
can be overridden by subclassing in pure python. The default
implementation of `func` calls into a `cdef` function `_func` that can
only be overridden by subclassing in cython code. This makes it possible
to subclass in python or cython and override `func` or `_func`
respectively. Unfortunately, the overhead of calling into the `cpdef`'d
function `func` reduces performance massively.

12.  `euler_12` demonstrates subclassing `ODES` from
`euler_11`. The performance is better than the pure python `euler_14` by a
factor of about 2. So using `cpdef` functions can provide better performance
for the pure python mode of sublcassing `ODES` at the expense of a 30-40 times
penalty for cython code.

13.  `euler_13` achieves the same flexibility as `euler_11` without the
performance cost by creating two extension types. A user who wants to
write something in pure python must subclass `pyODES` instead of `ODES`
and override `func` instead of `_func`. The performance of this variant is
about 33% worse than the fastest version `euler_07` while keeping the
intended flexibility that a user can override the methods in either python
or cython. It is, however, unfortunate to have to subclass a different
type and override a different method. Also if there would be subclasses of
`ODES`, then each would need a corresponding `py` variant to be usable
from pure python.

14.  `euler_14` demonstrates subclassing `pyODES` from
`euler_13`. The performance is better than the pure python `euler_01` by a
factor of about 3. The performance here is not as good as `euler_12` that
subclasses a `cpdef` method. It is improved upon later with `euler_19` and
`euler_20` that use a custom `Array` extension type to speed up calling into
the python function.

15.  `euler_15` demonstrates using a custom array class in place of
`numpy.ndarray`. This enables us to improve performance without sacrificing
the flexibility of `cpdef`. This gives an improvement of a factor of around 8
compared to the other `euler_11`. It is still 4 times as expensive as
`euler_12`.

16.  `euler_16` shows what happens if the `ODES` extension type if subclassed
from pure python. The performance is 30 times better than the original all
python `euler_01` and 4 times better than the next best python subclass
`euler_14`.

17  `euler_17` improves on `euler_15`'s cython performance by adding `set` and
`get` methods to the `Array` extension type. These `cdef` methods are able to
ourperform the special methods `__getitem__` and `__setitem__` for which it is
not possible to set a return type.

18.  `euler_18` should be the same as `euler_16` but using the `euler_18`
module.

19.  `euler_19` should be the same as `euler_13`. The changes here are
intended to improve performance when subclassing from python as in `euler_20`.

20.  `euler_20` performs significantly better than `euler_14` because of the
use of an `Array` extension type to boost performance when calling into the
python function.

Conclusion
----------

My interpretation of the above results is that the problem is really to do
with using `numpy.ndarray`. I think this point is demonstrated in the
performance difference between `euler_10` and `euler_11`. The only difference
between these two is that in `euler_11` I am calling through a `cpdef`
function that takes statically typed `numpy.ndarrays`. The cost of doing this
is comparable to each of the implementations that doesn't just work with
`double` pointers. It is possible, however, that the cost is really to do with
entering a `cpdef` function, although since I'm calling it from cython that
should (theoretically) be okay.

I can achieve much greater performance with functions that just use `double`
pointers. Unfortunately I cannot statically type the arguments of a `cpdef`
function to use `double` pointers as there is no corresponding python
alternative. If I had an alternative array implementation that was as
efficient as a c-style array, I could try that with a `cpdef` function to see
what the performance difference would be compared with `euler_12`. If it could
perform as well then I would have the flexibility of being able to subclass
the same methods of the same class in both cython and python while also having
the performance of `euler_13` in the pure cython case. Also the difference in
performance between `euler_14` and `euler_12` suggests that using `cpdef`
functions might be more efficient for python subclasses.

As it stands the performance difference between `cpdef` with `numpy.ndarray`
and `cdef` with `double` pointers is too big to be sacrificed in favour of the
flexibility that `cpdef` would give. If I can replicate those gains with a
custom array type, then I will use that. Otherwise I will stick with
`euler_12` and have two different classes, one to subclass from pure python
and the other from cython.

Update
------

Having tested a custom array class in `euler_15` I can see that the
performance definitely is much better than using `numpy.ndarray`. `euler_15`
outperforms `euler_11` by a factor of more than 10 and the only difference is
the use of the custom cython extension `Array` type as the data type to pass
into `func`. With this the choice becomes between `euler_12`'s less elegant
two class solution and `euler_15`'s slower but more elegant code.

`euler_12` gives us performance of 40 and 4500 micorseconds for cython and
python defined functions respectively.

`euler_15` gives us performance of 172 and 550 microseconds for the two cases.

Using `cpdef` functions makes `euler_15` faster from python but slower from
cython. Perhaps the performance of indexing the array class can be improved.

Update 2
--------

Having tested `euler_17`, I can see that we can get a performance within a
factor of 2 of the best performance by using the `cdef` methods `item` and
`itemset` instead of indexing the `Array` type. This improves substantially on
`euler_15` for these simple cases as an optional speedup for those who are
prepared to use special methods instead of indexing into the array.

The disadvantage of this approach is that the `itemset` and `item` methods are
incompatible with any other `Array` API. The resulting functions will not be
transparently applicable to `numpy.ndarray` or any other type that we decide
to place there.

Update 3
--------

Using the extension `Array` class in `euler_12` can give a boost to the pure
python performance. Now the best performers are:

`euler_15`: 174us and 598us
`euler_17`: 57us and 564us
`euler_19`: 40us and 833us

The advantages and disadvantages from a coding perspective are as follows.

`euler_15` allows the user to subclass the same type from cython or python and
override the same method with no need to change any of the syntax used in
order to achieve the level of performance reported above.

`euler_17` achieves better performance in the cython case at the expense of
requiring users to use a slightly awkward syntax in order to achieve the best
performance in cython. The best cython performance is several times better
than `euler_15` but about 50% slower than `euler_19`.

`euler_19` achieves the best performance in the cython case at a roughly 50%
performance penalty in the python case. It is fiddly to code as it requires a
separate `py` class for every extension type so that it can be overridden from
python without impacting in the performance when it is overridden from cython.

Final conclusion
----------------

I will probably use the `euler_19` approach as it offers the best performance.
Perhaps it can be augmented with bounds checking in a way that can be
subsequently disabled.

This means that everything should be defined in terms of extension types with
`cdef` methods using `double` pointers. Enabling a library user to subclass
from python will mean having an additional `py` class for each extension type.
This isn't very elegant but the cython performance is paramount here.

The problems that prevent me from using `euler_15` are that it is not possible
to make `__setitem__` and `__getitem__` more efficient in cython. I think this
is because I can't control the return types of the two functions. At least
that's the only difference between them and `item` and `itemset` that are able
to boost cython performance by a factor of 3 in this test.

As for `euler_17`, I am less in favour of introducing the `item`/`itemset`
functions in replacement of indexing than I am about creating redundant
classes just for performance reasons as is the case with `euler_19`.

Linux
-----

Timings on Linux::

    $ ./run.py
    stmt: euler_01.euler(euler_01.func, x0, t)      t: 11146 usecs
    stmt: euler_02.euler(euler_02.func, x0, t)      t: 12723 usecs
    stmt: euler_03.euler(euler_03.func, x0, t)      t: 2623 usecs
    stmt: euler_04.euler(x0, t)                     t: 1287 usecs
    stmt: euler_05.euler(x0, t)                     t: 1307 usecs
    stmt: euler_06.euler(x0, t)                     t: 1228 usecs
    stmt: euler_07.euler(x0, t)                     t: 22 usecs
    stmt: euler_08.euler(x0, t)                     t: 23 usecs
    stmt: euler_09.euler(x0, t)                     t: 23 usecs
    stmt: euler_10.euler(x0, t)                     t: 22 usecs
    stmt: euler_11.euler(x0, t)                     t: 1469 usecs
    stmt: euler_12.euler(x0, t) # py - euler_11     t: 2905 usecs
    stmt: euler_13.euler(x0, t)                     t: 23 usecs
    stmt: euler_14.euler(x0, t) # py - euler_13     t: 4132 usecs
    stmt: euler_15.euler(x0, t)                     t: 162 usecs
    stmt: euler_16.euler(x0, t) # py - euler_15     t: 748 usecs
    stmt: euler_17.euler(x0, t)                     t: 33 usecs
    stmt: euler_18.euler(x0, t) # py - euler_17     t: 765 usecs
    stmt: euler_19.euler(x0, t)                     t: 23 usecs
    stmt: euler_20.euler(x0, t) # py - euler_19     t: 1164 usecs

Notes on the above:

1. `euler_19` achieves the same speed as `euler_07`. Apparently there is no
penalty in using the cython vtable here.

2. The cython performance penalty for using `euler_15` over `eulerr_17` is a
factor of 8 here.
