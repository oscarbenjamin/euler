
from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
import numpy

def ext(name):
    return Extension(name, [name + '.pyx'], include_dirs=[numpy.get_include()])

ext_names = ['algos2', 'algos3', 'algos4', 'algos5',
             'algos6', 'algos7', 'algos8']
ext_modules = [ext(name) for name in ext_names]

setup(
    ext_modules=ext_modules,
    cmdclass = {'build_ext': build_ext}
)
