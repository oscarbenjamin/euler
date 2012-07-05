
from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
import numpy

ext_modules = [
    Extension('algos2', ['algos2.pyx'], include_dirs=[numpy.get_include()]),
]

setup(
    ext_modules=ext_modules,
    cmdclass = {'build_ext': build_ext}
)
