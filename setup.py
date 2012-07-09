
from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
import numpy

def ext(name):
    return Extension(name, [name + '.pyx'], include_dirs=[numpy.get_include()])

ext_names = ['euler_02', 'euler_03', 'euler_04', 'euler_05',
             'euler_06', 'euler_07', 'euler_08', 'euler_09',
             'euler_10', 'euler_11', 'euler_12', 'euler_15', 'euler_17']
ext_modules = [ext(name) for name in ext_names]

setup(
    ext_modules=ext_modules,
    cmdclass = {'build_ext': build_ext}
)
